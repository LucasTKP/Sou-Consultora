-- A receber: registrar_pagamento, pagamentos_parcelas, nomes_itens e isolamento (specs/a-receber).
begin;
\ir auxiliares/auxiliares.psql
select plan(16);

-- popular() cria, para cada consultora, a venda #1 (R$ 200) com a parcela de R$ 200
-- que já recebeu R$ 50 no Pix (saldo R$ 150).
select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset
select testes.popular(:'id_a');
select testes.popular(:'id_b');

select id as parcela_a from public.parcelas where consultora_id = :'id_a' \gset
select id as parcela_b from public.parcelas where consultora_id = :'id_b' \gset
select (now() at time zone 'America/Sao_Paulo')::date as hoje \gset

select testes.autenticar_como(:'id_a');

select throws_ok(format('select public.registrar_pagamento(%L, 200, %L, %L::date, null)', :'parcela_a', 'pix', :'hoje'),
  'SC400', 'O valor não pode passar do saldo da parcela (R$ 150,00).', 'valor além do saldo é recusado');
select throws_ok(format('select public.registrar_pagamento(%L, 0, %L, %L::date, null)', :'parcela_a', 'pix', :'hoje'),
  'SC400', 'Informe um valor maior que zero.', 'valor zero é recusado');
select throws_ok(format('select public.registrar_pagamento(%L, 10, %L, %L::date, null)', :'parcela_a', 'cheque', :'hoje'),
  'SC400', 'Escolha a forma de pagamento: Pix, cartão ou dinheiro.', 'forma inválida é recusada');
select throws_ok(format('select public.registrar_pagamento(%L, 10, %L, %L::date, null)', :'parcela_a', 'pix', :'hoje'::date + 1),
  'SC400', 'A data do pagamento não pode ser no futuro.', 'data futura é recusada');

select lives_ok(format('select public.registrar_pagamento(%L, 70, %L, %L::date, %L)', :'parcela_a', 'dinheiro', :'hoje', ' metade '),
  'pagamento parcial é aceito');
select results_eq(
  format('select valor_pago, qtd_pagamentos from public.resumo_parcelas where id = %L', :'parcela_a'),
  $$ values (120.00::numeric(12,2), 2) $$,
  'parcial soma ao que já foi pago');
select results_eq(
  format('select valor, forma_pagamento, observacao from public.pagamentos_parcelas where parcela_id = %L order by data_pagamento desc limit 1', :'parcela_a'),
  $$ values (70.00::numeric(12,2), 'dinheiro', 'metade') $$,
  'pagamentos_parcelas traz o pagamento com a forma e a observação');
select lives_ok(format('select public.registrar_pagamento(%L, 80, %L, %L::date, null)', :'parcela_a', 'pix', :'hoje'),
  'quitar o saldo restante é aceito');
select results_eq(
  format('select saldo, tem_pagamento from public.resumo_vendas where id = (select venda_id from public.parcelas where id = %L)', :'parcela_a'),
  $$ values (0.00::numeric(12,2), true) $$,
  'venda fica quitada');
select throws_ok(format('select public.registrar_pagamento(%L, 1, %L, %L::date, null)', :'parcela_a', 'pix', :'hoje'),
  'SC400', 'O valor não pode passar do saldo da parcela (R$ 0,00).', 'parcela quitada não recebe mais');
select is(
  (select nomes_itens from public.resumo_parcelas where id = :'parcela_a'),
  'Perfume', 'resumo_parcelas traz os nomes dos itens');

-- Isolamento
select throws_ok(format('select public.registrar_pagamento(%L, 10, %L, %L::date, null)', :'parcela_b', 'pix', :'hoje'),
  'SC400', 'Parcela não encontrada.', 'A não paga parcela de B');
select is_empty(format('select 1 from public.pagamentos_parcelas where parcela_id = %L', :'parcela_b'),
  'A não lê pagamentos de B');
reset role;
select is((select count(*)::int from public.pagamentos_parcela where parcela_id = :'parcela_b'), 1,
  'pagamentos de B permanecem');

select testes.anonimo();
select throws_ok('select count(*) from public.pagamentos_parcelas', '42501', null, 'anon não lê pagamentos');
select throws_ok(format('select public.registrar_pagamento(%L, 1, %L, %L::date, null)', :'parcela_a', 'pix', :'hoje'),
  '42501', null, 'anon não registra pagamento');
reset role;

select * from finish();
rollback;
