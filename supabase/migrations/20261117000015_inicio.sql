-- Início — Sou Consultora
-- View `lembretes_recompra` (security_invoker): para cada cliente e cada produto
-- com duração prevista, a ÚLTIMA compra dela daquele produto. A janela do
-- lembrete (7 dias antes da previsão até 60 depois) e a ordem ficam no app.
-- Serviços não entram (`produto_id` nulo) e venda cancelada some (cascade).

create view public.lembretes_recompra
with (security_invoker = true) as
select distinct on (v.consultora_id, v.cliente_id, iv.produto_id)
       v.cliente_id,
       c.nome                                               as cliente_nome,
       c.whatsapp                                           as cliente_whatsapp,
       iv.produto_id,
       p.nome                                               as produto_nome,
       p.durabilidade_dias,
       (v.data_venda at time zone 'America/Sao_Paulo')::date as ultima_compra
  from public.itens_venda iv
  join public.vendas v   on v.consultora_id = iv.consultora_id and v.id = iv.venda_id
  join public.produtos p on p.consultora_id = iv.consultora_id and p.id = iv.produto_id
  join public.clientes c on c.consultora_id = v.consultora_id  and c.id = v.cliente_id
 where iv.produto_id is not null
   and p.durabilidade_dias is not null
 order by v.consultora_id, v.cliente_id, iv.produto_id, v.data_venda desc;

revoke all on public.lembretes_recompra from anon, public;
grant select on public.lembretes_recompra to authenticated;
