-- Início: lembretes_recompra (última compra por cliente e produto) e isolamento (specs/inicio).
begin;
\ir auxiliares/auxiliares.psql
select plan(10);

-- popular() cria, para cada consultora, a cliente "Cliente", o produto "Perfume"
-- (sem duração prevista), o serviço "Sobrancelha" e a venda #1 com 1 Perfume.
select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset
select testes.popular(:'id_a');
select testes.popular(:'id_b');

select id as cliente_a from public.clientes where consultora_id = :'id_a' \gset
select id as produto_a from public.produtos where consultora_id = :'id_a' \gset
select id as servico_a from public.servicos where consultora_id = :'id_a' \gset
select id as venda1_a  from public.vendas   where consultora_id = :'id_a' \gset

-- A venda #1 foi há 90 dias.
update public.vendas set data_venda = now() - interval '90 days' where id = :'venda1_a';

select testes.autenticar_como(:'id_a');
select is_empty('select 1 from public.lembretes_recompra',
  'produto sem duração prevista não gera lembrete');
reset role;

-- Com duração de 60 dias o Perfume passa a gerar lembrete (A e B).
update public.produtos set durabilidade_dias = 60 where nome = 'Perfume';

select testes.autenticar_como(:'id_a');
select results_eq(
  'select cliente_nome, produto_nome, durabilidade_dias, ultima_compra from public.lembretes_recompra',
  $$ values ('Cliente'::text, 'Perfume'::text, 60,
             ((now() - interval '90 days') at time zone 'America/Sao_Paulo')::date) $$,
  'lembrete com a cliente, o produto, a duração e o dia da última compra');
reset role;

-- Recompra há 5 dias (com um serviço junto na mesma venda).
insert into public.vendas (id, consultora_id, cliente_id, codigo, data_venda, subtotal, total_descontos, total)
values ('00000000-0000-0000-0000-0000000000a2', :'id_a', :'cliente_a', 2, now() - interval '5 days', 260, 0, 260);
insert into public.itens_venda (consultora_id, venda_id, produto_id, quantidade, preco_unitario, subtotal)
values (:'id_a', '00000000-0000-0000-0000-0000000000a2', :'produto_a', 1, 200, 200);
insert into public.itens_venda (consultora_id, venda_id, servico_id, quantidade, preco_unitario, subtotal, baixar_estoque)
values (:'id_a', '00000000-0000-0000-0000-0000000000a2', :'servico_a', 1, 60, 60, false);

select testes.autenticar_como(:'id_a');
select is((select count(*)::int from public.lembretes_recompra), 1,
  'uma linha por cliente e produto (o serviço não entra)');
select is((select ultima_compra from public.lembretes_recompra),
  ((now() - interval '5 days') at time zone 'America/Sao_Paulo')::date,
  'a recompra vira a última compra');
reset role;

-- Cancelar a recompra (apaga a venda e os itens) volta à compra anterior.
delete from public.vendas where id = '00000000-0000-0000-0000-0000000000a2';
select testes.autenticar_como(:'id_a');
select is((select ultima_compra from public.lembretes_recompra),
  ((now() - interval '90 days') at time zone 'America/Sao_Paulo')::date,
  'venda cancelada deixa de contar');

-- Isolamento
select is((select count(*)::int from public.lembretes_recompra), 1,
  'A só vê o próprio lembrete');
select is_empty(
  format('select 1 from public.lembretes_recompra where cliente_id in (select id from public.clientes where consultora_id = %L)', :'id_b'),
  'A não vê lembretes das clientes de B');
select testes.autenticar_como(:'id_b');
select is((select count(*)::int from public.lembretes_recompra), 1, 'B vê só o dela');
select isnt((select cliente_id from public.lembretes_recompra), :'cliente_a'::uuid,
  'o lembrete de B não é da cliente de A');
reset role;

select testes.anonimo();
select throws_ok('select count(*) from public.lembretes_recompra', '42501', null,
  'anon não lê lembretes');
reset role;

select * from finish();
rollback;
