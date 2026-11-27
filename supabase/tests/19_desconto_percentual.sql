-- Desconto em porcentagem no item da venda e isolamento da coluna nova.
begin;
\ir auxiliares/auxiliares.psql
select plan(9);

select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset
select testes.popular(:'id_a');
select testes.popular(:'id_b');
update public.consultoras set ultimo_codigo_venda = 1 where id in (:'id_a', :'id_b');

select id as cliente_a from public.clientes where consultora_id = :'id_a' \gset
select id as sobrancelha_a from public.servicos where consultora_id = :'id_a' \gset
select id as venda_b from public.vendas where consultora_id = :'id_b' \gset
select (now() at time zone 'America/Sao_Paulo')::date as hoje \gset

select testes.autenticar_como(:'id_a');

-- Serviço de R$ 60 com 12,5%: R$ 7,50 (o "desconto" enviado é ignorado).
select public.concluir_venda(:'cliente_a', :'hoje'::date, null,
  jsonb_build_array(jsonb_build_object('servico_id', :'sobrancelha_a', 'quantidade', 1,
                                       'desconto', 1, 'percentual_desconto', 12.5)),
  jsonb_build_array(jsonb_build_object('valor', 52.50, 'data_vencimento', :'hoje')),
  null) as venda \gset

select results_eq(
  format('select desconto, percentual_desconto, subtotal from public.itens_vendas where venda_id = %L', :'venda'),
  $$ values (7.50::numeric(12,2), 12.50::numeric(5,2), 52.50::numeric(12,2)) $$,
  'grava a porcentagem e calcula o valor');
select results_eq(
  format('select total_descontos, total from public.vendas where id = %L', :'venda'),
  $$ values (7.50::numeric(12,2), 52.50::numeric(12,2)) $$,
  'totais usam o valor calculado');

select lives_ok(
  format('select public.editar_venda(%L, %L, %L::date, null, %L::jsonb, %L::jsonb, null)', :'venda', :'cliente_a', :'hoje',
    jsonb_build_array(jsonb_build_object('servico_id', :'sobrancelha_a', 'quantidade', 1, 'desconto', 5)),
    jsonb_build_array(jsonb_build_object('valor', 55, 'data_vencimento', :'hoje'))),
  'edita trocando para desconto em reais');
select results_eq(
  format('select desconto, percentual_desconto from public.itens_vendas where venda_id = %L', :'venda'),
  $$ values (5.00::numeric(12,2), null::numeric(5,2)) $$,
  'em reais a porcentagem fica nula');

select throws_ok(
  format('select public.concluir_venda(%L, %L::date, null, %L::jsonb, %L::jsonb, null)', :'cliente_a', :'hoje',
    jsonb_build_array(jsonb_build_object('servico_id', :'sobrancelha_a', 'quantidade', 1, 'percentual_desconto', 101)),
    jsonb_build_array(jsonb_build_object('valor', 1, 'data_vencimento', :'hoje'))),
  'SC400', 'O desconto não pode passar de 100%.', 'acima de 100% é recusado');

-- Isolamento
select is_empty(
  format('select 1 from public.itens_vendas where venda_id = %L', :'venda_b'),
  'A não lê itens de B');
select is_empty(
  format('update public.itens_venda set percentual_desconto = 50 where venda_id = %L returning 1', :'venda_b'),
  'A não altera itens de B');

reset role;
select is(
  (select percentual_desconto from public.itens_venda where venda_id = :'venda_b'),
  null, 'item de B permanece');

select testes.anonimo();
select throws_ok('select percentual_desconto from public.itens_vendas', '42501', null, 'anon não lê os itens');
reset role;

select * from finish();
rollback;
