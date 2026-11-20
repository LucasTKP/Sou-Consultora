-- Clientes — quantidade de parcelas atrasadas no resumo.
-- `resumo_clientes` ganha `qtd_atrasadas` (parcelas vencidas com saldo > 0), usada
-- no card da cliente ("2 atrasadas · R$ 1.250,00"). Nada é gravado: a coluna é
-- calculada das parcelas e pagamentos, no fim da view para manter as demais.
-- A view continua security_invoker (herda o RLS) e com os mesmos grants.

create or replace view public.resumo_clientes
with (security_invoker = true) as
with
  hoje as (
    select (now() at time zone 'America/Sao_Paulo')::date as dia
  ),
  saldo_parcelas as (
    select v.cliente_id,
           p.data_vencimento,
           p.valor - coalesce((select sum(pp.valor)
                                 from public.pagamentos_parcela pp
                                where pp.parcela_id = p.id), 0) as saldo
      from public.parcelas p
      join public.vendas v on v.id = p.venda_id
  ),
  financeiro as (
    select sp.cliente_id,
           sum(sp.saldo) filter (where sp.saldo > 0) as saldo_devedor,
           sum(sp.saldo) filter (where sp.saldo > 0 and sp.data_vencimento < h.dia) as valor_atrasado,
           sum(sp.saldo) filter (where sp.saldo > 0 and sp.data_vencimento = h.dia) as valor_vence_hoje,
           count(*)      filter (where sp.saldo > 0 and sp.data_vencimento < h.dia) as qtd_atrasadas
      from saldo_parcelas sp
     cross join hoje h
     group by sp.cliente_id
  ),
  compras as (
    select v.cliente_id,
           count(*)          as qtd_compras,
           sum(v.total)      as total_compras,
           max(v.data_venda) as ultima_compra
      from public.vendas v
     group by v.cliente_id
  )
select c.id,
       c.nome,
       c.whatsapp,
       c.data_nascimento,
       c.created_at,
       coalesce(co.qtd_compras, 0)::integer       as qtd_compras,
       coalesce(co.total_compras, 0)::numeric(12, 2)   as total_compras,
       co.ultima_compra,
       coalesce(f.saldo_devedor, 0)::numeric(12, 2)    as saldo_devedor,
       coalesce(f.valor_atrasado, 0)::numeric(12, 2)   as valor_atrasado,
       coalesce(f.valor_vence_hoje, 0)::numeric(12, 2) as valor_vence_hoje,
       coalesce(f.qtd_atrasadas, 0)::integer           as qtd_atrasadas
  from public.clientes c
  left join compras co   on co.cliente_id = c.id
  left join financeiro f on f.cliente_id = c.id;

revoke all on public.resumo_clientes from anon, public;
grant select on public.resumo_clientes to authenticated;
