-- A pagar: resumo_boletos, trigger da data de pagamento e isolamento (specs/a-pagar).
begin;
\ir auxiliares/auxiliares.psql
select plan(22);

-- popular() cria, para cada consultora, o fornecedor "Marca" e um boleto de R$ 500 vencendo hoje.
select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset
select testes.popular(:'id_a');
select testes.popular(:'id_b');

select id as boleto_a from public.boletos where consultora_id = :'id_a' \gset
select id as boleto_b from public.boletos where consultora_id = :'id_b' \gset
select id as fornecedor_a from public.fornecedores where consultora_id = :'id_a' \gset
select id as fornecedor_b from public.fornecedores where consultora_id = :'id_b' \gset
select (now() at time zone 'America/Sao_Paulo')::date as hoje \gset

select testes.autenticar_como(:'id_a');

-- View
select results_eq(
  format('select fornecedor_nome, fornecedor_ativo, valor, data_pagamento from public.resumo_boletos where id = %L', :'boleto_a'),
  $$ values ('Marca'::text, true, 500.00::numeric(12,2), null::date) $$,
  'resumo_boletos traz o boleto com a marca');

-- Gravar (sem consultora_id: o default é auth.uid())
select lives_ok(
  format($$insert into public.boletos (fornecedor_id, valor, data_vencimento, forma_pagamento, observacoes)
           values (%L, 680, %L::date + 7, 'pix', '  Ciclo 15  ')$$, :'fornecedor_a', :'hoje'),
  'A lança boleto sem informar consultora_id');
select is(
  (select observacoes from public.boletos where consultora_id = :'id_a' and valor = 680),
  'Ciclo 15', 'observação sem espaços nas pontas');
select lives_ok(
  format($$insert into public.boletos (fornecedor_id, valor, data_vencimento, observacoes) values (%L, 10, %L, '   ')$$,
    :'fornecedor_a', :'hoje'),
  'observação só com espaços é aceita');
select is(
  (select observacoes from public.boletos where consultora_id = :'id_a' and valor = 10),
  null, 'observação vazia vira nulo');
select throws_ok(
  format('insert into public.boletos (fornecedor_id, valor, data_vencimento) values (%L, 0, %L)', :'fornecedor_a', :'hoje'),
  '23514', null, 'valor zero é recusado');
select throws_ok(
  format($$insert into public.boletos (fornecedor_id, valor, data_vencimento, forma_pagamento) values (%L, 10, %L, 'cheque')$$,
    :'fornecedor_a', :'hoje'),
  '23514', null, 'forma inválida é recusada');

-- Pagar e desfazer
select throws_ok(
  format('update public.boletos set data_pagamento = %L::date + 1 where id = %L', :'hoje', :'boleto_a'),
  'SC400', 'A data do pagamento não pode ser no futuro.', 'pagamento com data futura é recusado');
select throws_ok(
  format('insert into public.boletos (fornecedor_id, valor, data_vencimento, data_pagamento) values (%L, 10, %L, %L::date + 1)',
    :'fornecedor_a', :'hoje', :'hoje'),
  'SC400', 'A data do pagamento não pode ser no futuro.', 'lançar já pago no futuro é recusado');
select lives_ok(
  format('update public.boletos set data_pagamento = %L::date - 1 where id = %L', :'hoje', :'boleto_a'),
  'pagar com a data de ontem é aceito');
select is((select data_pagamento from public.resumo_boletos where id = :'boleto_a'), (:'hoje'::date - 1),
  'boleto fica pago com a data escolhida');
select lives_ok(format('update public.boletos set data_pagamento = null where id = %L', :'boleto_a'),
  'desfazer o pagamento é aceito');
select is((select data_pagamento from public.boletos where id = :'boleto_a'), null, 'boleto volta a não pago');

-- Isolamento
select is_empty(format('select 1 from public.resumo_boletos where id = %L', :'boleto_b'), 'A não lê boletos de B');
select is_empty(format('update public.boletos set data_pagamento = %L where id = %L returning 1', :'hoje', :'boleto_b'),
  'A não paga boleto de B');
select is_empty(format('delete from public.boletos where id = %L returning 1', :'boleto_b'), 'A não exclui boleto de B');
select throws_ok(
  format('insert into public.boletos (fornecedor_id, valor, data_vencimento) values (%L, 10, %L)', :'fornecedor_b', :'hoje'),
  '23503', null, 'A não lança boleto com o fornecedor de B');
select throws_ok(
  format('insert into public.boletos (consultora_id, fornecedor_id, valor, data_vencimento) values (%L, %L, 10, %L)',
    :'id_b', :'fornecedor_b', :'hoje'),
  '42501', null, 'A não grava boleto como B');
select throws_ok(
  format('insert into storage.objects (bucket_id, name, owner_id) values (%L, %L, %L)',
    'comprovantes', :'id_b' || '/boletos/' || :'boleto_b' || '/x.pdf', :'id_a'),
  '42501', null, 'A não anexa comprovante na pasta de B');
reset role;
select results_eq(
  format('select valor, data_pagamento from public.boletos where id = %L', :'boleto_b'),
  $$ values (500.00::numeric(12,2), null::date) $$,
  'boleto de B permanece intacto');

select testes.anonimo();
select throws_ok('select count(*) from public.resumo_boletos', '42501', null, 'anon não lê o resumo de boletos');
select throws_ok('select count(*) from public.boletos', '42501', null, 'anon não lê boletos');
reset role;

select * from finish();
rollback;
