-- A receber — Sou Consultora (change `a-receber`)
-- 1. registrar_pagamento: pagamento inteiro ou parcial de uma parcela (nunca além do saldo).
-- 2. View pagamentos_parcelas (security_invoker).
-- 3. resumo_parcelas ganha `nomes_itens` (busca por produto/serviço em A receber).

-- =====================================================================
-- 1. Registrar pagamento
-- =====================================================================

create function public.registrar_pagamento(
  p_parcela_id uuid,
  p_valor      numeric,
  p_forma      text,
  p_data       date,
  p_observacao text
) returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_valor_parcela numeric(12, 2);
  v_saldo         numeric(12, 2);
  v_id            uuid;
begin
  -- RLS: parcela de outra consultora não é encontrada. Trava contra pagamento simultâneo.
  select p.valor into v_valor_parcela
    from public.parcelas p
   where p.id = p_parcela_id
     for update;
  if not found then
    raise exception 'Parcela não encontrada.' using errcode = 'SC400';
  end if;

  if p_valor is null or p_valor <= 0 then
    raise exception 'Informe um valor maior que zero.' using errcode = 'SC400';
  end if;
  if p_forma is null or p_forma not in ('pix', 'cartao', 'dinheiro') then
    raise exception 'Escolha a forma de pagamento: Pix, cartão ou dinheiro.' using errcode = 'SC400';
  end if;
  if p_data is null or p_data > (now() at time zone 'America/Sao_Paulo')::date then
    raise exception 'A data do pagamento não pode ser no futuro.' using errcode = 'SC400';
  end if;

  select v_valor_parcela - coalesce(sum(pp.valor), 0)
    into v_saldo
    from public.pagamentos_parcela pp
   where pp.parcela_id = p_parcela_id;

  if p_valor > v_saldo then
    raise exception 'O valor não pode passar do saldo da parcela (R$ %).',
      replace(to_char(v_saldo, 'FM999999990.00'), '.', ',')
      using errcode = 'SC400';
  end if;

  insert into public.pagamentos_parcela (parcela_id, valor, forma_pagamento, data_pagamento, observacao)
  values (p_parcela_id, p_valor, p_forma, interno.momento_da_venda(p_data), nullif(btrim(p_observacao), ''))
  returning id into v_id;

  return v_id;
end $$;

revoke execute on function public.registrar_pagamento(uuid, numeric, text, date, text) from public, anon;
grant execute on function public.registrar_pagamento(uuid, numeric, text, date, text) to authenticated;

-- =====================================================================
-- 2. Pagamentos
-- =====================================================================

create view public.pagamentos_parcelas
with (security_invoker = true) as
select pp.id,
       pp.parcela_id,
       p.venda_id,
       pp.valor,
       pp.forma_pagamento,
       pp.data_pagamento,
       pp.observacao
  from public.pagamentos_parcela pp
  join public.parcelas p on p.consultora_id = pp.consultora_id and p.id = pp.parcela_id;

revoke all on public.pagamentos_parcelas from anon, public;
grant select on public.pagamentos_parcelas to authenticated;

-- =====================================================================
-- 3. resumo_parcelas + nomes dos itens (coluna nova no fim)
-- =====================================================================

create or replace view public.resumo_parcelas
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
       c.whatsapp                                  as cliente_whatsapp,
       coalesce((select string_agg(iv.nome, ' | ' order by iv.id)
                   from public.itens_vendas iv
                  where iv.venda_id = p.venda_id), '') as nomes_itens
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
