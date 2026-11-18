-- Vendas: concluir/editar/cancelar, FIFO com custo médio, parcelas, views e isolamento (specs/vendas).
begin;
\ir auxiliares/auxiliares.psql
select plan(32);

-- popular() cria, para cada consultora: cliente "Cliente", produto "Perfume" (R$ 200)
-- com o lote #1 (2 disponíveis a R$ 120), serviço "Sobrancelha" (R$ 60) e a venda #1.
select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset
select testes.popular(:'id_a');
select testes.popular(:'id_b');
-- A venda de popular() foi gravada direto com o código 1.
update public.consultoras set ultimo_codigo_venda = 1 where id in (:'id_a', :'id_b');

select id as cliente_a from public.clientes where consultora_id = :'id_a' \gset
select id as cliente_b from public.clientes where consultora_id = :'id_b' \gset
select id as perfume_a from public.produtos where consultora_id = :'id_a' \gset
select id as perfume_b from public.produtos where consultora_id = :'id_b' \gset
select id as sobrancelha_a from public.servicos where consultora_id = :'id_a' \gset
select id as venda_b from public.vendas where consultora_id = :'id_b' \gset
select id as lote1_a from public.lotes_estoque where consultora_id = :'id_a' \gset
select (now() at time zone 'America/Sao_Paulo')::date as hoje \gset
-- popular() usa current_date (UTC); fixa o lote #1 um dia antes do #2 para a
-- ordem "mais antigo primeiro" não depender do horário em que o teste roda.
update public.lancamentos_estoque set data_compra = :'hoje'::date - 1
 where consultora_id = :'id_a';

select testes.autenticar_como(:'id_a');

-- Lote #2: 3 un a R$ 150 (comprado hoje, depois do #1).
select public.lancar_estoque(:'hoje'::date, jsonb_build_array(
  jsonb_build_object('produto_id', :'perfume_a', 'quantidade', 3, 'custo_unitario', 150)));
select id as lote2_a from public.lotes_estoque where produto_id = :'perfume_a' and numero_lote = 2 \gset

-- ---------------------------------------------------------------------
-- Concluir
-- ---------------------------------------------------------------------
select public.concluir_venda(:'cliente_a', :'hoje'::date, ' Entregar sexta ',
  jsonb_build_array(jsonb_build_object('produto_id', :'perfume_a', 'quantidade', 3, 'desconto', 10)),
  jsonb_build_array(jsonb_build_object('valor', 590, 'data_vencimento', :'hoje'::date + 30)),
  null) as venda1 \gset

select results_eq(
  format('select codigo, subtotal, total_descontos, total, observacoes from public.vendas where id = %L', :'venda1'),
  $$ values (2, 600.00::numeric(12,2), 10.00::numeric(12,2), 590.00::numeric(12,2), 'Entregar sexta') $$,
  'código sequencial, preço do catálogo e totais');
select results_eq(
  format('select quantidade_disponivel from public.lotes_estoque where id in (%L, %L) order by numero_lote', :'lote1_a', :'lote2_a'),
  $$ values (0), (2) $$,
  'consome primeiro o lote mais antigo');
select is(
  (select custo_unitario from public.itens_venda where venda_id = :'venda1'),
  130.00::numeric(12,2), 'custo do item é a média ponderada dos lotes consumidos');
select is(
  (select count(*)::int from public.saidas_estoque s join public.itens_venda i on i.id = s.item_venda_id where i.venda_id = :'venda1'),
  2, 'uma saída por lote consumido');
select is((select ultimo_codigo_venda from public.consultoras where id = :'id_a'), 2, 'contador de código avança');

-- Erros de negócio: nada é gravado
select throws_ok(
  format('select public.concluir_venda(%L, %L::date, null, %L::jsonb, %L::jsonb, null)', :'cliente_a', :'hoje',
    jsonb_build_array(jsonb_build_object('produto_id', :'perfume_a', 'quantidade', 5)),
    jsonb_build_array(jsonb_build_object('valor', 1000, 'data_vencimento', :'hoje'))),
  'SC400', 'Estoque insuficiente para "Perfume": 2 un disponíveis.', 'sem saldo suficiente é recusado');
select is((select ultimo_codigo_venda from public.consultoras where id = :'id_a'), 2, 'venda recusada não gasta código');
select throws_ok(
  format('select public.concluir_venda(%L, %L::date, null, %L::jsonb, %L::jsonb, null)', :'cliente_a', :'hoje',
    jsonb_build_array(jsonb_build_object('servico_id', :'sobrancelha_a', 'quantidade', 1)),
    jsonb_build_array(jsonb_build_object('valor', 50, 'data_vencimento', :'hoje'))),
  'SC400', 'A soma das parcelas (R$ 50,00) precisa ser igual ao total (R$ 60,00).', 'parcelas que não somam são recusadas');
select throws_ok(
  format('select public.concluir_venda(%L, %L::date, null, %L::jsonb, %L::jsonb, null)', :'cliente_a', :'hoje'::date + 1,
    jsonb_build_array(jsonb_build_object('servico_id', :'sobrancelha_a', 'quantidade', 1)),
    jsonb_build_array(jsonb_build_object('valor', 60, 'data_vencimento', :'hoje'))),
  'SC400', 'A data da venda não pode ser no futuro.', 'data futura é recusada');
select throws_ok(
  format('select public.concluir_venda(%L, %L::date, null, %L::jsonb, %L::jsonb, null)', :'cliente_a', :'hoje',
    jsonb_build_array(jsonb_build_object('servico_id', :'sobrancelha_a', 'quantidade', 1, 'desconto', 61)),
    jsonb_build_array(jsonb_build_object('valor', 1, 'data_vencimento', :'hoje'))),
  'SC400', 'O desconto de "Sobrancelha" não pode passar do valor do item.', 'desconto maior que o item é recusado');
select throws_ok(
  format('select public.concluir_venda(%L, %L::date, null, %L::jsonb, %L::jsonb, null)', :'cliente_a', :'hoje',
    jsonb_build_array(jsonb_build_object('servico_id', :'sobrancelha_a', 'quantidade', 1),
                      jsonb_build_object('servico_id', :'sobrancelha_a', 'quantidade', 2)),
    jsonb_build_array(jsonb_build_object('valor', 180, 'data_vencimento', :'hoje'))),
  'SC400', 'Cada produto ou serviço pode aparecer uma vez só no pedido.', 'item repetido é recusado');

-- Encomenda (sem baixa) + serviço, em 2 parcelas, com a entrada paga no Pix
select public.concluir_venda(:'cliente_a', :'hoje'::date, null,
  jsonb_build_array(
    jsonb_build_object('produto_id', :'perfume_a', 'quantidade', 10, 'baixar_estoque', false),
    jsonb_build_object('servico_id', :'sobrancelha_a', 'quantidade', 1)),
  jsonb_build_array(
    jsonb_build_object('valor', 1000, 'data_vencimento', :'hoje'),
    jsonb_build_object('valor', 1060, 'data_vencimento', :'hoje'::date + 30)),
  jsonb_build_object('forma', 'pix')) as venda3 \gset

select results_eq(
  format('select baixar_estoque, custo_unitario from public.itens_venda where venda_id = %L order by servico_id nulls first', :'venda3'),
  $$ values (false, 0.00::numeric(12,2)), (false, 0.00::numeric(12,2)) $$,
  'encomenda e serviço não baixam estoque e usam o custo do cadastro (zero)');
select is((select quantidade_disponivel from public.lotes_estoque where id = :'lote2_a'), 2, 'encomenda não mexe no estoque');
select results_eq(
  format('select numero_parcela, valor_pago, qtd_parcelas from public.resumo_parcelas where venda_id = %L order by numero_parcela', :'venda3'),
  $$ values (1, 1000.00::numeric(12,2), 2), (2, 0.00::numeric(12,2), 2) $$,
  'entrada paga a 1ª parcela inteira');
select results_eq(
  format('select qtd_itens, qtd_unidades, valor_pago, saldo, tem_pagamento, qtd_parcelas_pagas from public.resumo_vendas where id = %L', :'venda3'),
  $$ values (2, 11, 1000.00::numeric(12,2), 1060.00::numeric(12,2), true, 1) $$,
  'resumo da venda com itens, pago e saldo');
select is(
  (select nomes_itens like '%Perfume%' and nomes_itens like '%Sobrancelha%' from public.resumo_vendas where id = :'venda3'),
  true, 'resumo traz os nomes dos itens para a busca');
select results_eq(
  format('select nome, categoria_servico from public.itens_vendas where venda_id = %L and servico_id is not null', :'venda3'),
  format('select s.nome, c.nome from public.servicos s join public.categorias c on c.id = s.categoria_id where s.id = %L', :'sobrancelha_a'),
  'itens_vendas traz o nome do serviço e a categoria');

-- ---------------------------------------------------------------------
-- Editar e cancelar
-- ---------------------------------------------------------------------
select lives_ok(
  format('select public.editar_venda(%L, %L, %L::date, null, %L::jsonb, %L::jsonb, null)', :'venda1', :'cliente_a', :'hoje',
    jsonb_build_array(jsonb_build_object('produto_id', :'perfume_a', 'quantidade', 1)),
    jsonb_build_array(jsonb_build_object('valor', 200, 'data_vencimento', :'hoje'))),
  'venda sem pagamento é editada');
select results_eq(
  format('select quantidade_disponivel from public.lotes_estoque where id in (%L, %L) order by numero_lote', :'lote1_a', :'lote2_a'),
  $$ values (1), (3) $$,
  'editar devolve o estoque e consome de novo do lote mais antigo');
select results_eq(
  format('select codigo, total from public.vendas where id = %L', :'venda1'),
  $$ values (2, 200.00::numeric(12,2)) $$,
  'editar mantém o código e regrava o total');
select throws_ok(
  format('select public.editar_venda(%L, %L, %L::date, null, %L::jsonb, %L::jsonb, null)', :'venda3', :'cliente_a', :'hoje',
    jsonb_build_array(jsonb_build_object('servico_id', :'sobrancelha_a', 'quantidade', 1)),
    jsonb_build_array(jsonb_build_object('valor', 60, 'data_vencimento', :'hoje'))),
  'SC400', 'Esta venda já tem pagamento e não pode ser editada.', 'venda com pagamento não é editada');

select lives_ok(format('select public.cancelar_venda(%L)', :'venda1'), 'cancelar apaga a venda');
select is_empty(format('select 1 from public.vendas where id = %L', :'venda1'), 'a venda some');
select results_eq(
  format('select quantidade_disponivel from public.lotes_estoque where id in (%L, %L) order by numero_lote', :'lote1_a', :'lote2_a'),
  $$ values (2), (3) $$,
  'cancelar devolve as unidades aos lotes');
select lives_ok(format('select public.cancelar_venda(%L)', :'venda3'), 'venda com pagamento também pode ser cancelada');
select is_empty(format('select 1 from public.parcelas where venda_id = %L', :'venda3'), 'parcelas e pagamentos somem junto');

-- ---------------------------------------------------------------------
-- Isolamento
-- ---------------------------------------------------------------------
select throws_ok(
  format('select public.concluir_venda(%L, %L::date, null, %L::jsonb, %L::jsonb, null)', :'cliente_b', :'hoje',
    jsonb_build_array(jsonb_build_object('servico_id', :'sobrancelha_a', 'quantidade', 1)),
    jsonb_build_array(jsonb_build_object('valor', 60, 'data_vencimento', :'hoje'))),
  'SC400', 'Cliente não encontrada.', 'A não vende para cliente de B');
select throws_ok(
  format('select public.concluir_venda(%L, %L::date, null, %L::jsonb, %L::jsonb, null)', :'cliente_a', :'hoje',
    jsonb_build_array(jsonb_build_object('produto_id', :'perfume_b', 'quantidade', 1, 'baixar_estoque', false)),
    jsonb_build_array(jsonb_build_object('valor', 200, 'data_vencimento', :'hoje'))),
  'SC400', 'Produto não encontrado.', 'A não vende produto de B');
select throws_ok(format('select public.cancelar_venda(%L)', :'venda_b'),
  'SC400', 'Venda não encontrada.', 'A não cancela venda de B');
select is((select count(*)::int from public.resumo_vendas), 1, 'A vê só as próprias vendas');

reset role;
select is((select count(*)::int from public.vendas where id = :'venda_b'), 1, 'venda de B permanece');

select testes.anonimo();
select throws_ok('select count(*) from public.resumo_vendas', '42501', null, 'anon não lê as vendas');
reset role;

select * from finish();
rollback;
