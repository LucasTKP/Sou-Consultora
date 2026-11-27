-- Guarda a porcentagem quando o desconto do item é digitado em %.
-- `desconto` continua sendo o valor em reais (totais e relatórios não mudam);
-- `percentual_desconto` fica nulo quando o desconto foi digitado em R$.
-- A tabela já tem RLS forçado e policies; a coluna nova é coberta por elas.

alter table public.itens_venda
  add column percentual_desconto numeric(5, 2)
  check (percentual_desconto > 0 and percentual_desconto <= 100);

-- p_itens passa a aceitar "percentual_desconto": numeric (opcional). Quando
-- vem, vale sobre "desconto". Continua SECURITY INVOKER.
create or replace function interno.gravar_conteudo_venda(
  p_venda_id   uuid,
  p_data_venda timestamptz,
  p_itens      jsonb,
  p_parcelas   jsonb,
  p_pagamento  jsonb
) returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_item       record;
  v_nome       text;
  v_preco      numeric(12, 2);
  v_custo      numeric(12, 2);
  v_baixar     boolean;
  v_bruto      numeric(12, 2);
  v_desconto   numeric(12, 2);
  v_item_id    uuid;
  v_subtotal   numeric(12, 2) := 0;
  v_descontos  numeric(12, 2) := 0;
  v_total      numeric(12, 2);
  v_soma       numeric(12, 2);
  v_qtd        integer;
  v_unicos     integer;
  v_parcela    record;
  v_primeira   uuid;
  v_forma      text;
begin
  if p_itens is null or jsonb_typeof(p_itens) <> 'array' or jsonb_array_length(p_itens) = 0 then
    raise exception 'Adicione pelo menos um produto ou serviço.' using errcode = 'SC400';
  end if;

  select count(*), count(distinct coalesce(x.produto_id, x.servico_id))
    into v_qtd, v_unicos
    from jsonb_to_recordset(p_itens) as x (produto_id uuid, servico_id uuid);
  if v_unicos <> v_qtd then
    raise exception 'Cada produto ou serviço pode aparecer uma vez só no pedido.' using errcode = 'SC400';
  end if;

  for v_item in
    select x.produto_id, x.servico_id, x.quantidade,
           coalesce(x.desconto, 0) as desconto,
           x.percentual_desconto,
           coalesce(x.baixar_estoque, true) as baixar_estoque
      from jsonb_to_recordset(p_itens)
           as x (produto_id uuid, servico_id uuid, quantidade integer,
                 desconto numeric(12, 2), percentual_desconto numeric,
                 baixar_estoque boolean)
  loop
    if num_nonnulls(v_item.produto_id, v_item.servico_id) <> 1 then
      raise exception 'Cada item precisa ser um produto ou um serviço.' using errcode = 'SC400';
    end if;
    if v_item.quantidade is null or v_item.quantidade < 1 then
      raise exception 'A quantidade de cada item precisa ser de pelo menos 1.' using errcode = 'SC400';
    end if;
    if v_item.desconto < 0 or v_item.percentual_desconto < 0 then
      raise exception 'O desconto não pode ser negativo.' using errcode = 'SC400';
    end if;
    if v_item.percentual_desconto > 100 then
      raise exception 'O desconto não pode passar de 100%%.' using errcode = 'SC400';
    end if;

    if v_item.produto_id is not null then
      select p.nome, p.preco_venda, coalesce(p.preco_custo, 0)
        into v_nome, v_preco, v_custo
        from public.produtos p
       where p.id = v_item.produto_id;
      if not found then
        raise exception 'Produto não encontrado.' using errcode = 'SC400';
      end if;
      v_baixar := v_item.baixar_estoque;
    else
      select s.nome, s.preco_cobrado, coalesce(s.custo_materiais, 0)
        into v_nome, v_preco, v_custo
        from public.servicos s
       where s.id = v_item.servico_id;
      if not found then
        raise exception 'Serviço não encontrado.' using errcode = 'SC400';
      end if;
      v_baixar := false;
    end if;

    v_bruto := v_preco * v_item.quantidade;
    -- Com porcentagem, o valor é calculado aqui, sobre o preço do catálogo.
    v_desconto := coalesce(
      round(v_bruto * v_item.percentual_desconto / 100, 2), v_item.desconto);
    if v_desconto > v_bruto then
      raise exception 'O desconto de "%" não pode passar do valor do item.', v_nome
        using errcode = 'SC400';
    end if;

    insert into public.itens_venda (
      venda_id, produto_id, servico_id, quantidade, preco_unitario,
      custo_unitario, desconto, percentual_desconto, subtotal, baixar_estoque
    ) values (
      p_venda_id, v_item.produto_id, v_item.servico_id, v_item.quantidade, v_preco,
      v_custo, v_desconto, nullif(v_item.percentual_desconto, 0),
      v_bruto - v_desconto, v_baixar
    ) returning id into v_item_id;

    if v_baixar then
      update public.itens_venda
         set custo_unitario = interno.baixar_estoque(v_item_id, v_item.produto_id, v_nome, v_item.quantidade)
       where id = v_item_id;
    end if;

    v_subtotal := v_subtotal + v_bruto;
    v_descontos := v_descontos + v_desconto;
  end loop;

  v_total := v_subtotal - v_descontos;
  if v_total <= 0 then
    raise exception 'O total da venda precisa ser maior que zero.' using errcode = 'SC400';
  end if;

  update public.vendas
     set subtotal = v_subtotal, total_descontos = v_descontos, total = v_total
   where id = p_venda_id;

  -- Parcelas: pelo menos uma, valores > 0, datas preenchidas e soma = total.
  if p_parcelas is null or jsonb_typeof(p_parcelas) <> 'array' or jsonb_array_length(p_parcelas) = 0 then
    raise exception 'Informe como a cliente vai pagar.' using errcode = 'SC400';
  end if;
  if exists (select 1 from jsonb_to_recordset(p_parcelas) as x (valor numeric, data_vencimento date)
              where x.valor is null or x.valor <= 0 or x.data_vencimento is null) then
    raise exception 'Cada parcela precisa de valor e data de vencimento.' using errcode = 'SC400';
  end if;
  select sum(x.valor) into v_soma
    from jsonb_to_recordset(p_parcelas) as x (valor numeric(12, 2));
  if v_soma <> v_total then
    raise exception 'A soma das parcelas (R$ %) precisa ser igual ao total (R$ %).',
      replace(to_char(v_soma, 'FM999999990.00'), '.', ','),
      replace(to_char(v_total, 'FM999999990.00'), '.', ',')
      using errcode = 'SC400';
  end if;

  for v_parcela in
    select x.valor, x.data_vencimento, n.numero
      from jsonb_array_elements(p_parcelas) with ordinality as n (elemento, numero),
           jsonb_to_record(n.elemento) as x (valor numeric(12, 2), data_vencimento date)
     order by n.numero
  loop
    insert into public.parcelas (venda_id, numero_parcela, valor, data_vencimento)
    values (p_venda_id, v_parcela.numero, v_parcela.valor, v_parcela.data_vencimento)
    returning id into v_item_id;
    if v_parcela.numero = 1 then
      v_primeira := v_item_id;
    end if;
  end loop;

  -- Entrada: a 1ª parcela já foi recebida, inteira, na data da venda.
  if p_pagamento is not null and jsonb_typeof(p_pagamento) = 'object' then
    v_forma := p_pagamento ->> 'forma';
    if v_forma is null or v_forma not in ('pix', 'cartao', 'dinheiro') then
      raise exception 'Escolha a forma de pagamento: Pix, cartão ou dinheiro.' using errcode = 'SC400';
    end if;
    insert into public.pagamentos_parcela (parcela_id, valor, forma_pagamento, data_pagamento)
    select v_primeira, p.valor, v_forma, p_data_venda
      from public.parcelas p
     where p.id = v_primeira;
  end if;
end $$;

-- A coluna nova entra no fim: `create or replace view` só permite acrescentar.
create or replace view public.itens_vendas
with (security_invoker = true) as
select i.id,
       i.venda_id,
       i.produto_id,
       i.servico_id,
       coalesce(pr.nome, s.nome)          as nome,
       coalesce(pr.foto_url, s.foto_url)  as foto_url,
       cs.nome                            as categoria_servico,
       i.quantidade,
       i.preco_unitario,
       i.custo_unitario,
       i.desconto,
       i.subtotal,
       i.baixar_estoque,
       i.percentual_desconto
  from public.itens_venda i
  left join public.produtos pr  on pr.consultora_id = i.consultora_id and pr.id = i.produto_id
  left join public.servicos s   on s.consultora_id = i.consultora_id and s.id = i.servico_id
  left join public.categorias cs on cs.consultora_id = s.consultora_id and cs.id = s.categoria_id;
