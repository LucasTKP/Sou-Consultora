-- Vendas — Sou Consultora (change `vendas`)
-- 1. Schema `interno`: lógica comum das funções de venda (o PostgREST não expõe).
-- 2. Funções concluir_venda, editar_venda e cancelar_venda (tudo ou nada).
-- 3. Views resumo_vendas, itens_vendas e resumo_parcelas (security_invoker).
--
-- Regras: preço sempre do catálogo; produto com baixa consome os lotes do mais
-- antigo (data da compra, número do lote) e grava o custo médio dos consumidos;
-- sem baixa usa o preço de custo do cadastro; serviço usa o custo de materiais.
-- Erros de negócio saem com 'SC400' e mensagem para a consultora.

-- =====================================================================
-- 1. Lógica interna
-- =====================================================================

create schema if not exists interno;
revoke all on schema interno from public, anon;
grant usage on schema interno to authenticated;

-- Devolve aos lotes as unidades que a venda consumiu (as saídas somem junto
-- com os itens, pelo cascade).
create function interno.devolver_estoque(p_venda_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.lotes_estoque l
     set quantidade_disponivel = l.quantidade_disponivel + s.qtd
    from (
      select s.lote_id, sum(s.quantidade) as qtd
        from public.saidas_estoque s
        join public.itens_venda i on i.id = s.item_venda_id
       where i.venda_id = p_venda_id
       group by s.lote_id
    ) s
   where l.id = s.lote_id;
end $$;

-- Baixa [p_quantidade] do produto, do lote mais antigo para o mais novo, e
-- devolve o custo unitário médio das unidades consumidas.
create function interno.baixar_estoque(
  p_item_id uuid,
  p_produto_id uuid,
  p_nome text,
  p_quantidade integer
) returns numeric
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_lote       record;
  v_saldo      integer;
  v_falta      integer := p_quantidade;
  v_tira       integer;
  v_custo      numeric := 0;
begin
  -- Trava os lotes do produto contra outra venda simultânea.
  perform 1 from public.lotes_estoque l where l.produto_id = p_produto_id for update;

  select coalesce(sum(l.quantidade_disponivel), 0)
    into v_saldo
    from public.lotes_estoque l
   where l.produto_id = p_produto_id;

  if v_saldo < p_quantidade then
    raise exception 'Estoque insuficiente para "%": % un disponíveis.', p_nome, v_saldo
      using errcode = 'SC400';
  end if;

  for v_lote in
    select l.id, l.quantidade_disponivel, l.custo_unitario
      from public.lotes_estoque l
      join public.lancamentos_estoque e
        on e.consultora_id = l.consultora_id and e.id = l.lancamento_id
     where l.produto_id = p_produto_id
       and l.quantidade_disponivel > 0
     order by e.data_compra, l.numero_lote
  loop
    v_tira := least(v_falta, v_lote.quantidade_disponivel);

    update public.lotes_estoque
       set quantidade_disponivel = quantidade_disponivel - v_tira
     where id = v_lote.id;

    insert into public.saidas_estoque (item_venda_id, lote_id, quantidade)
    values (p_item_id, v_lote.id, v_tira);

    v_custo := v_custo + v_tira * v_lote.custo_unitario;
    v_falta := v_falta - v_tira;
    exit when v_falta = 0;
  end loop;

  return round(v_custo / p_quantidade, 2);
end $$;

-- Grava itens, totais, parcelas e o pagamento de entrada de uma venda já criada.
create function interno.gravar_conteudo_venda(
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
           coalesce(x.baixar_estoque, true) as baixar_estoque
      from jsonb_to_recordset(p_itens)
           as x (produto_id uuid, servico_id uuid, quantidade integer,
                 desconto numeric(12, 2), baixar_estoque boolean)
  loop
    if num_nonnulls(v_item.produto_id, v_item.servico_id) <> 1 then
      raise exception 'Cada item precisa ser um produto ou um serviço.' using errcode = 'SC400';
    end if;
    if v_item.quantidade is null or v_item.quantidade < 1 then
      raise exception 'A quantidade de cada item precisa ser de pelo menos 1.' using errcode = 'SC400';
    end if;
    if v_item.desconto < 0 then
      raise exception 'O desconto não pode ser negativo.' using errcode = 'SC400';
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
    if v_item.desconto > v_bruto then
      raise exception 'O desconto de "%" não pode passar do valor do item.', v_nome
        using errcode = 'SC400';
    end if;

    insert into public.itens_venda (
      venda_id, produto_id, servico_id, quantidade, preco_unitario,
      custo_unitario, desconto, subtotal, baixar_estoque
    ) values (
      p_venda_id, v_item.produto_id, v_item.servico_id, v_item.quantidade, v_preco,
      v_custo, v_item.desconto, v_bruto - v_item.desconto, v_baixar
    ) returning id into v_item_id;

    if v_baixar then
      update public.itens_venda
         set custo_unitario = interno.baixar_estoque(v_item_id, v_item.produto_id, v_nome, v_item.quantidade)
       where id = v_item_id;
    end if;

    v_subtotal := v_subtotal + v_bruto;
    v_descontos := v_descontos + v_item.desconto;
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

-- Data escolhida + hora atual de São Paulo (hoje → agora); nunca no futuro.
create function interno.momento_da_venda(p_data date)
returns timestamptz
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_agora timestamp := now() at time zone 'America/Sao_Paulo';
begin
  if p_data is null or p_data > v_agora::date then
    raise exception 'A data da venda não pode ser no futuro.' using errcode = 'SC400';
  end if;
  if p_data = v_agora::date then
    return now();
  end if;
  return (p_data + v_agora::time) at time zone 'America/Sao_Paulo';
end $$;

revoke all on all functions in schema interno from public, anon;
grant execute on all functions in schema interno to authenticated;

-- =====================================================================
-- 2. Funções públicas (RPC)
-- =====================================================================
-- p_itens:    [{"produto_id"|"servico_id": uuid, "quantidade": int, "desconto": numeric, "baixar_estoque": bool}]
-- p_parcelas: [{"valor": numeric, "data_vencimento": date}]  (soma = total)
-- p_pagamento: {"forma": "pix"|"cartao"|"dinheiro"} ou null (entrada = 1ª parcela inteira)

create function public.concluir_venda(
  p_cliente_id  uuid,
  p_data_venda  date,
  p_observacoes text,
  p_itens       jsonb,
  p_parcelas    jsonb,
  p_pagamento   jsonb
) returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_momento timestamptz := interno.momento_da_venda(p_data_venda);
  v_codigo  integer;
  v_venda   uuid;
begin
  -- RLS: cliente de outra consultora não é encontrada.
  if not exists (select 1 from public.clientes c where c.id = p_cliente_id) then
    raise exception 'Cliente não encontrada.' using errcode = 'SC400';
  end if;

  update public.consultoras
     set ultimo_codigo_venda = ultimo_codigo_venda + 1
   where id = (select auth.uid())
  returning ultimo_codigo_venda into v_codigo;
  if v_codigo is null then
    raise exception 'Cadastro da consultora não encontrado.' using errcode = 'SC400';
  end if;

  insert into public.vendas (cliente_id, codigo, data_venda, subtotal, total_descontos, total, observacoes)
  values (p_cliente_id, v_codigo, v_momento, 0, 0, 0, nullif(btrim(p_observacoes), ''))
  returning id into v_venda;

  perform interno.gravar_conteudo_venda(v_venda, v_momento, p_itens, p_parcelas, p_pagamento);
  return v_venda;
end $$;

create function public.editar_venda(
  p_venda_id    uuid,
  p_cliente_id  uuid,
  p_data_venda  date,
  p_observacoes text,
  p_itens       jsonb,
  p_parcelas    jsonb,
  p_pagamento   jsonb
) returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_venda   record;
  v_momento timestamptz;
begin
  select v.id, v.data_venda
    into v_venda
    from public.vendas v
   where v.id = p_venda_id
     for update;
  if not found then
    raise exception 'Venda não encontrada.' using errcode = 'SC400';
  end if;

  if exists (
    select 1 from public.pagamentos_parcela pp
      join public.parcelas p on p.id = pp.parcela_id
     where p.venda_id = p_venda_id
  ) then
    raise exception 'Esta venda já tem pagamento e não pode ser editada.' using errcode = 'SC400';
  end if;

  if not exists (select 1 from public.clientes c where c.id = p_cliente_id) then
    raise exception 'Cliente não encontrada.' using errcode = 'SC400';
  end if;

  -- Mesma data: mantém o horário original da venda.
  if p_data_venda = (v_venda.data_venda at time zone 'America/Sao_Paulo')::date then
    v_momento := v_venda.data_venda;
  else
    v_momento := interno.momento_da_venda(p_data_venda);
  end if;

  perform interno.devolver_estoque(p_venda_id);
  delete from public.itens_venda where venda_id = p_venda_id;
  delete from public.parcelas where venda_id = p_venda_id;

  update public.vendas
     set cliente_id = p_cliente_id,
         data_venda = v_momento,
         observacoes = nullif(btrim(p_observacoes), ''),
         subtotal = 0, total_descontos = 0, total = 0
   where id = p_venda_id;

  perform interno.gravar_conteudo_venda(p_venda_id, v_momento, p_itens, p_parcelas, p_pagamento);
  return p_venda_id;
end $$;

create function public.cancelar_venda(p_venda_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  perform 1 from public.vendas v where v.id = p_venda_id for update;
  if not found then
    raise exception 'Venda não encontrada.' using errcode = 'SC400';
  end if;

  perform interno.devolver_estoque(p_venda_id);
  delete from public.vendas where id = p_venda_id;
end $$;

revoke execute on function public.concluir_venda(uuid, date, text, jsonb, jsonb, jsonb) from public, anon;
grant execute on function public.concluir_venda(uuid, date, text, jsonb, jsonb, jsonb) to authenticated;
revoke execute on function public.editar_venda(uuid, uuid, date, text, jsonb, jsonb, jsonb) from public, anon;
grant execute on function public.editar_venda(uuid, uuid, date, text, jsonb, jsonb, jsonb) to authenticated;
revoke execute on function public.cancelar_venda(uuid) from public, anon;
grant execute on function public.cancelar_venda(uuid) to authenticated;

-- =====================================================================
-- 3. Views
-- =====================================================================

-- Uma parcela com o que já foi pago, a venda e a cliente (Vendas e A receber).
create view public.resumo_parcelas
with (security_invoker = true) as
select p.id,
       p.venda_id,
       p.numero_parcela,
       p.valor,
       p.data_vencimento,
       coalesce(pg.valor_pago, 0)::numeric(12, 2)  as valor_pago,
       coalesce(pg.qtd_pagamentos, 0)::integer     as qtd_pagamentos,
       pg.ultimo_pagamento,
       v.codigo                                    as venda_codigo,
       v.data_venda,
       v.total                                     as venda_total,
       (select count(*) from public.parcelas p2 where p2.venda_id = p.venda_id)::integer as qtd_parcelas,
       v.cliente_id,
       c.nome                                      as cliente_nome,
       c.whatsapp                                  as cliente_whatsapp
  from public.parcelas p
  join public.vendas v   on v.consultora_id = p.consultora_id and v.id = p.venda_id
  join public.clientes c on c.consultora_id = v.consultora_id and c.id = v.cliente_id
  left join (
    select pp.parcela_id,
           sum(pp.valor)          as valor_pago,
           count(*)               as qtd_pagamentos,
           max(pp.data_pagamento) as ultimo_pagamento
      from public.pagamentos_parcela pp
     group by pp.parcela_id
  ) pg on pg.parcela_id = p.id;

-- Um item da venda com o nome e a foto do produto ou do serviço.
create view public.itens_vendas
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
       i.baixar_estoque
  from public.itens_venda i
  left join public.produtos pr  on pr.consultora_id = i.consultora_id and pr.id = i.produto_id
  left join public.servicos s   on s.consultora_id = i.consultora_id and s.id = i.servico_id
  left join public.categorias cs on cs.consultora_id = s.consultora_id and cs.id = s.categoria_id;

-- Uma venda com a cliente, os itens resumidos e a situação das parcelas.
-- "Hoje" é o dia em São Paulo; o status (quitada / atrasada / em aberto) é
-- calculado no app a partir de saldo e valor_atrasado.
create view public.resumo_vendas
with (security_invoker = true) as
with
  hoje as (
    select (now() at time zone 'America/Sao_Paulo')::date as dia
  ),
  itens as (
    select iv.venda_id,
           count(*)::integer                                   as qtd_itens,
           sum(iv.quantidade)::integer                         as qtd_unidades,
           string_agg(iv.nome, ' | ' order by iv.id)          as nomes_itens,
           (array_agg(iv.nome order by iv.nome))[1]            as primeiro_item
      from public.itens_vendas iv
     group by iv.venda_id
  ),
  parcelas as (
    select rp.venda_id,
           count(*)::integer                                              as qtd_parcelas,
           count(*) filter (where rp.valor_pago >= rp.valor)::integer     as qtd_parcelas_pagas,
           sum(rp.valor_pago)                                             as valor_pago,
           sum(greatest(rp.valor - rp.valor_pago, 0))                     as saldo,
           sum(greatest(rp.valor - rp.valor_pago, 0))
             filter (where rp.data_vencimento < h.dia)                    as valor_atrasado,
           min(rp.data_vencimento) filter (where rp.valor_pago < rp.valor) as proximo_vencimento,
           bool_or(rp.qtd_pagamentos > 0)                                  as tem_pagamento
      from public.resumo_parcelas rp
     cross join hoje h
     group by rp.venda_id
  )
select v.id,
       v.codigo,
       v.cliente_id,
       c.nome                                      as cliente_nome,
       c.whatsapp                                  as cliente_whatsapp,
       v.data_venda,
       v.subtotal,
       v.total_descontos,
       v.total,
       v.observacoes,
       coalesce(i.qtd_itens, 0)                    as qtd_itens,
       coalesce(i.qtd_unidades, 0)                 as qtd_unidades,
       coalesce(i.nomes_itens, '')                 as nomes_itens,
       i.primeiro_item,
       coalesce(pa.qtd_parcelas, 0)                as qtd_parcelas,
       coalesce(pa.qtd_parcelas_pagas, 0)          as qtd_parcelas_pagas,
       coalesce(pa.valor_pago, 0)::numeric(12, 2)     as valor_pago,
       coalesce(pa.saldo, 0)::numeric(12, 2)          as saldo,
       coalesce(pa.valor_atrasado, 0)::numeric(12, 2) as valor_atrasado,
       pa.proximo_vencimento,
       coalesce(pa.tem_pagamento, false)           as tem_pagamento
  from public.vendas v
  join public.clientes c on c.consultora_id = v.consultora_id and c.id = v.cliente_id
  left join itens i     on i.venda_id = v.id
  left join parcelas pa on pa.venda_id = v.id;

revoke all on public.resumo_parcelas, public.itens_vendas, public.resumo_vendas from anon, public;
grant select on public.resumo_parcelas, public.itens_vendas, public.resumo_vendas to authenticated;
