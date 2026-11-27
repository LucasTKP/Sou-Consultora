-- Estoque — Sou Consultora (change `estoque`)
-- 1. lancar_estoque: grava a compra em lotes, tudo ou nada (um lançamento por marca).
-- 2. apagar_lote: apaga lote que nunca teve saída (e o lançamento, se ficar vazio).
-- 3. Views lotes_produtos e saidas_produtos (security_invoker → herdam o RLS).
--
-- Erros de negócio saem com o código 'SC400' e uma mensagem em português para a
-- consultora; o app mostra essa mensagem. Os demais erros seguem os códigos do Postgres.

-- =====================================================================
-- 1. Lançar estoque
-- =====================================================================
-- p_itens: [{"produto_id": uuid, "quantidade": int, "custo_unitario": numeric, "validade": date|null}]
-- Cada lote é da marca do próprio produto: itens de marcas diferentes viram
-- lançamentos diferentes, todos com a mesma data. O número do lote é o maior
-- do produto + 1, calculado com o produto travado (for update).

create function public.lancar_estoque(p_data_compra date, p_itens jsonb)
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_hoje       date := (now() at time zone 'America/Sao_Paulo')::date;
  v_qtd_itens  integer;
  v_qtd_unicos integer;
  v_encontrados integer;
  v_marca      uuid;
  v_item       record;
  v_lancamento uuid;
  v_numero     integer;
  v_gravados   integer := 0;
begin
  if p_data_compra is null or p_data_compra > v_hoje then
    raise exception 'A data da compra não pode ser no futuro.' using errcode = 'SC400';
  end if;

  if p_itens is null or jsonb_typeof(p_itens) <> 'array' or jsonb_array_length(p_itens) = 0 then
    raise exception 'Adicione pelo menos um produto à compra.' using errcode = 'SC400';
  end if;

  select count(*), count(distinct x.produto_id)
    into v_qtd_itens, v_qtd_unicos
    from jsonb_to_recordset(p_itens) as x (produto_id uuid);

  if v_qtd_unicos <> v_qtd_itens then
    raise exception 'Cada produto pode aparecer uma vez só na compra.' using errcode = 'SC400';
  end if;

  if exists (select 1 from jsonb_to_recordset(p_itens) as x (produto_id uuid, quantidade integer)
              where x.produto_id is null or x.quantidade is null or x.quantidade < 1) then
    raise exception 'A quantidade de cada produto precisa ser de pelo menos 1.' using errcode = 'SC400';
  end if;

  if exists (select 1 from jsonb_to_recordset(p_itens) as x (custo_unitario numeric)
              where x.custo_unitario is null or x.custo_unitario < 0) then
    raise exception 'Informe o custo unitário de cada produto.' using errcode = 'SC400';
  end if;

  if exists (select 1 from jsonb_to_recordset(p_itens) as x (validade date)
              where x.validade < p_data_compra) then
    raise exception 'A validade do lote não pode ser antes da data da compra.' using errcode = 'SC400';
  end if;

  -- Trava os produtos contra lançamentos simultâneos. O RLS só deixa ver os da
  -- consultora: produto de outra (ou inexistente) não é encontrado.
  select count(*)
    into v_encontrados
    from (select p.id
            from public.produtos p
           where p.id in (select x.produto_id from jsonb_to_recordset(p_itens) as x (produto_id uuid))
             for update) travados;

  if v_encontrados <> v_qtd_itens then
    raise exception 'Produto não encontrado.' using errcode = 'SC400';
  end if;

  for v_marca in
    select distinct p.fornecedor_id
      from public.produtos p
     where p.id in (select x.produto_id from jsonb_to_recordset(p_itens) as x (produto_id uuid))
     order by p.fornecedor_id
  loop
    insert into public.lancamentos_estoque (fornecedor_id, data_compra)
    values (v_marca, p_data_compra)
    returning id into v_lancamento;

    for v_item in
      select x.produto_id, x.quantidade, x.custo_unitario, x.validade
        from jsonb_to_recordset(p_itens)
             as x (produto_id uuid, quantidade integer, custo_unitario numeric(12, 2), validade date)
        join public.produtos p on p.id = x.produto_id
       where p.fornecedor_id = v_marca
       order by x.produto_id
    loop
      select coalesce(max(l.numero_lote), 0) + 1
        into v_numero
        from public.lotes_estoque l
       where l.produto_id = v_item.produto_id;

      insert into public.lotes_estoque (
        lancamento_id, produto_id, numero_lote, quantidade,
        quantidade_disponivel, custo_unitario, validade
      ) values (
        v_lancamento, v_item.produto_id, v_numero, v_item.quantidade,
        v_item.quantidade, v_item.custo_unitario, v_item.validade
      );
      v_gravados := v_gravados + 1;
    end loop;
  end loop;

  return v_gravados;
end $$;

revoke execute on function public.lancar_estoque(date, jsonb) from public, anon;
grant execute on function public.lancar_estoque(date, jsonb) to authenticated;

-- =====================================================================
-- 2. Apagar lote sem vendas
-- =====================================================================

create function public.apagar_lote(p_lote_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_lancamento uuid;
begin
  begin
    delete from public.lotes_estoque
     where id = p_lote_id
    returning lancamento_id into v_lancamento;
  exception
    when foreign_key_violation then
      raise exception 'Este lote já teve vendas e não pode ser apagado.' using errcode = 'SC400';
  end;

  -- RLS: lote de outra consultora não é encontrado.
  if v_lancamento is null then
    raise exception 'Lote não encontrado.' using errcode = 'SC400';
  end if;

  delete from public.lancamentos_estoque e
   where e.id = v_lancamento
     and not exists (select 1 from public.lotes_estoque l where l.lancamento_id = v_lancamento);
end $$;

revoke execute on function public.apagar_lote(uuid) from public, anon;
grant execute on function public.apagar_lote(uuid) to authenticated;

-- =====================================================================
-- 3. Views da aba Estoque
-- =====================================================================

-- Um lote, com a data da compra, o fornecedor e quantas unidades já saíram dele.
create view public.lotes_produtos
with (security_invoker = true) as
select l.id,
       l.produto_id,
       l.numero_lote,
       l.quantidade,
       l.quantidade_disponivel,
       l.custo_unitario,
       l.validade,
       e.data_compra,
       f.nome                                   as fornecedor_nome,
       coalesce(s.qtd_saidas, 0)::integer       as qtd_saidas,
       l.created_at
  from public.lotes_estoque l
  join public.lancamentos_estoque e on e.consultora_id = l.consultora_id and e.id = l.lancamento_id
  join public.fornecedores f        on f.consultora_id = e.consultora_id and f.id = e.fornecedor_id
  left join (
    select lote_id, sum(quantidade) as qtd_saidas
      from public.saidas_estoque
     group by lote_id
  ) s on s.lote_id = l.id;

revoke all on public.lotes_produtos from anon, public;
grant select on public.lotes_produtos to authenticated;

-- Um item de venda que consumiu o produto do estoque (baixa ligada).
create view public.saidas_produtos
with (security_invoker = true) as
select i.id         as item_venda_id,
       i.produto_id,
       v.id         as venda_id,
       v.data_venda,
       c.nome       as cliente_nome,
       i.quantidade,
       i.subtotal
  from public.itens_venda i
  join public.vendas v   on v.consultora_id = i.consultora_id and v.id = i.venda_id
  join public.clientes c on c.consultora_id = v.consultora_id and c.id = v.cliente_id
 where i.produto_id is not null
   and i.baixar_estoque;

revoke all on public.saidas_produtos from anon, public;
grant select on public.saidas_produtos to authenticated;
