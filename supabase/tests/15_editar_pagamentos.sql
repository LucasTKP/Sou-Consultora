-- Editar e excluir pagamentos, e editar parcelas da venda (change `editar-pagamentos`).
begin;
\ir auxiliares/auxiliares.psql
select plan(19);

select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset
select testes.popular(:'id_a');
select testes.popular(:'id_b');
-- A venda de popular() foi gravada direto com o código 1.
update public.consultoras set ultimo_codigo_venda = 1 where id in (:'id_a', :'id_b');

select id as cliente_a from public.clientes where consultora_id = :'id_a' \gset
select id as sobrancelha_a from public.servicos where consultora_id = :'id_a' \gset
select id as parcela_b from public.parcelas where consultora_id = :'id_b' \gset
select id as pagamento_b from public.pagamentos_parcela where consultora_id = :'id_b' \gset
select (now() at time zone 'America/Sao_Paulo')::date as hoje \gset

select testes.autenticar_como(:'id_a');

-- Venda nova da A: serviço de R$ 60 em 2 parcelas de R$ 30; a 1ª recebe R$ 10 no Pix.
select public.concluir_venda(:'cliente_a', :'hoje'::date, null,
  jsonb_build_array(jsonb_build_object('servico_id', :'sobrancelha_a', 'quantidade', 1)),
  jsonb_build_array(
    jsonb_build_object('valor', 30, 'data_vencimento', :'hoje'::date),
    jsonb_build_object('valor', 30, 'data_vencimento', :'hoje'::date + 30)),
  null) as venda_nova \gset
select id as p1 from public.parcelas where venda_id = :'venda_nova' and numero_parcela = 1 \gset
select id as p2 from public.parcelas where venda_id = :'venda_nova' and numero_parcela = 2 \gset
select public.registrar_pagamento(:'p1', 10, 'pix', :'hoje'::date, 'entrada') as pag1 \gset

-- ---------------------------------------------------------------------
-- Editar pagamento
-- ---------------------------------------------------------------------
select lives_ok(format('select public.editar_pagamento(%L, 20, %L, %L::date, %L)', :'pag1', 'dinheiro', :'hoje', ' ajustado '),
  'editar pagamento é aceito');
select results_eq(
  format('select valor, forma_pagamento, observacao from public.pagamentos_parcela where id = %L', :'pag1'),
  $$ values (20.00::numeric(12,2), 'dinheiro', 'ajustado') $$,
  'valor, forma e observação são gravados');
select throws_ok(format('select public.editar_pagamento(%L, 31, %L, %L::date, null)', :'pag1', 'pix', :'hoje'),
  'SC400', 'O valor não pode passar do saldo da parcela (R$ 30,00).', 'valor além do saldo da parcela é recusado');
select throws_ok(format('select public.editar_pagamento(%L, 0, %L, %L::date, null)', :'pag1', 'pix', :'hoje'),
  'SC400', 'Informe um valor maior que zero.', 'valor zero é recusado');
select throws_ok(format('select public.editar_pagamento(%L, 10, %L, %L::date, null)', :'pag1', 'cheque', :'hoje'),
  'SC400', 'Escolha a forma de pagamento: Pix, cartão ou dinheiro.', 'forma inválida é recusada');
select throws_ok(format('select public.editar_pagamento(%L, 10, %L, %L::date, null)', :'pag1', 'pix', :'hoje'::date + 1),
  'SC400', 'A data do pagamento não pode ser no futuro.', 'data futura é recusada');
select throws_ok(format('select public.editar_pagamento(%L, 1, %L, %L::date, null)', :'pagamento_b', 'pix', :'hoje'),
  'SC400', 'Pagamento não encontrado.', 'A não edita pagamento de B');

-- ---------------------------------------------------------------------
-- Excluir pagamento
-- ---------------------------------------------------------------------
select lives_ok(format('select public.excluir_pagamento(%L)', :'pag1'), 'excluir pagamento é aceito');
select results_eq(
  format('select valor_pago from public.resumo_parcelas where id = %L', :'p1'),
  $$ values (0.00::numeric(12,2)) $$,
  'o que foi pago volta ao saldo da parcela');
select throws_ok(format('select public.excluir_pagamento(%L)', :'pagamento_b'),
  'SC400', 'Pagamento não encontrado.', 'A não exclui pagamento de B');

-- ---------------------------------------------------------------------
-- Editar parcelas
-- ---------------------------------------------------------------------
select throws_ok(
  format('select public.editar_parcelas(%L, %L::jsonb)', :'venda_nova',
    jsonb_build_array(
      jsonb_build_object('id', :'p1', 'valor', 40, 'data_vencimento', :'hoje'::date),
      jsonb_build_object('id', :'p2', 'valor', 10, 'data_vencimento', :'hoje'::date + 30))),
  'SC400', 'A soma das parcelas (R$ 50,00) precisa ser igual ao total (R$ 60,00).', 'parcelas que não somam o total são recusadas');
select lives_ok(
  format('select public.editar_parcelas(%L, %L::jsonb)', :'venda_nova',
    jsonb_build_array(
      jsonb_build_object('id', :'p1', 'valor', 40, 'data_vencimento', :'hoje'::date),
      jsonb_build_object('id', :'p2', 'valor', 20, 'data_vencimento', :'hoje'::date + 30))),
  'editar parcelas sem pagamento é aceito');
select results_eq(
  format('select valor from public.parcelas where venda_id = %L order by numero_parcela', :'venda_nova'),
  $$ values (40.00::numeric(12,2)), (20.00::numeric(12,2)) $$,
  'os novos valores são gravados');

-- Parcela com pagamento: valor e vencimento mudam, sem ficar abaixo do recebido.
select public.registrar_pagamento(:'p1', 10, 'pix', :'hoje'::date, null);
select throws_ok(
  format('select public.editar_parcelas(%L, %L::jsonb)', :'venda_nova',
    jsonb_build_array(
      jsonb_build_object('id', :'p1', 'valor', 5, 'data_vencimento', :'hoje'::date),
      jsonb_build_object('id', :'p2', 'valor', 55, 'data_vencimento', :'hoje'::date + 30))),
  'SC400', 'O valor da parcela 1 não pode ser menor que o já recebido (R$ 10,00).', 'valor abaixo do recebido é recusado');
select lives_ok(
  format('select public.editar_parcelas(%L, %L::jsonb)', :'venda_nova',
    jsonb_build_array(
      jsonb_build_object('id', :'p1', 'valor', 30, 'data_vencimento', :'hoje'::date + 5),
      jsonb_build_object('id', :'p2', 'valor', 30, 'data_vencimento', :'hoje'::date + 10))),
  'parcela com pagamento muda valor e vencimento');
select results_eq(
  format('select valor from public.parcelas where venda_id = %L order by numero_parcela', :'venda_nova'),
  $$ values (30.00::numeric(12,2)), (30.00::numeric(12,2)) $$,
  'o novo valor da parcela recebida é gravado');
select throws_ok(
  format('select public.editar_parcelas(%L, %L::jsonb)', :'venda_nova',
    jsonb_build_array(jsonb_build_object('id', :'p1', 'valor', 40, 'data_vencimento', :'hoje'::date))),
  'SC400', 'Confira as parcelas da venda.', 'é preciso enviar todas as parcelas da venda');
select throws_ok(
  format('select public.editar_parcelas(%L, %L::jsonb)', :'parcela_b',
    jsonb_build_array(jsonb_build_object('id', :'parcela_b', 'valor', 200, 'data_vencimento', :'hoje'::date))),
  'SC400', 'Venda não encontrada.', 'A não edita parcelas de B');

-- Isolamento: os pagamentos de B continuam lá.
reset role;
select is((select count(*)::int from public.pagamentos_parcela where id = :'pagamento_b'), 1,
  'pagamentos de B permanecem');

select * from finish();
rollback;
