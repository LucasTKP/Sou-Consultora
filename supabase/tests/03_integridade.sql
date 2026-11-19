-- Regras de integridade do modelo (specs/modelo-de-dados).
begin;
\ir auxiliares/auxiliares.psql
select plan(30);

select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset
select testes.popular(:'id_a');

select id as venda    from public.vendas        where consultora_id = :'id_a' \gset
select id as produto  from public.produtos      where consultora_id = :'id_a' \gset
select id as servico  from public.servicos      where consultora_id = :'id_a' \gset
select id as cliente  from public.clientes      where consultora_id = :'id_a' \gset
select id as fornec   from public.fornecedores  where consultora_id = :'id_a' \gset
select id as lote     from public.lotes_estoque where consultora_id = :'id_a' \gset
select id as lanc     from public.lancamentos_estoque where consultora_id = :'id_a' \gset
select id as parcela  from public.parcelas      where consultora_id = :'id_a' \gset
select categoria_id as cat_prod from public.produtos where id = :'produto' \gset

select testes.autenticar_como(:'id_a');

-- Estrutura
select is(
  (select count(*)::int from information_schema.tables where table_schema = 'public' and table_type = 'BASE TABLE'),
  16, 'as 15 entidades + configuracoes existem');

-- Item: produto XOR serviço; serviço não baixa estoque
select throws_ok(format(
  'insert into public.itens_venda (venda_id, produto_id, servico_id, quantidade, preco_unitario, subtotal, baixar_estoque)
   values (%L, %L, %L, 1, 10, 10, false)', :'venda', :'produto', :'servico'),
  '23514', null, 'item com produto e serviço é recusado');
select throws_ok(format(
  'insert into public.itens_venda (venda_id, quantidade, preco_unitario, subtotal) values (%L, 1, 10, 10)', :'venda'),
  '23514', null, 'item sem produto nem serviço é recusado');
select throws_ok(format(
  'insert into public.itens_venda (venda_id, servico_id, quantidade, preco_unitario, subtotal, baixar_estoque)
   values (%L, %L, 1, 10, 10, true)', :'venda', :'servico'),
  '23514', null, 'serviço com baixa de estoque é recusado');
select lives_ok(format(
  'insert into public.itens_venda (venda_id, servico_id, quantidade, preco_unitario, subtotal, baixar_estoque)
   values (%L, %L, 1, 10, 10, false)', :'venda', :'servico'),
  'serviço sem baixa de estoque é aceito');

-- Valores e quantidades
select throws_ok(format(
  'insert into public.produtos (fornecedor_id, categoria_id, nome, preco_venda) values (%L, %L, %L, -1)', :'fornec', :'cat_prod', 'X'),
  '23514', null, 'preço negativo é recusado');
select throws_ok(format(
  'insert into public.itens_venda (venda_id, produto_id, quantidade, preco_unitario, subtotal) values (%L, %L, 0, 10, 10)', :'venda', :'produto'),
  '23514', null, 'quantidade zero no item é recusada');
select throws_ok(format(
  'insert into public.parcelas (venda_id, numero_parcela, valor, data_vencimento) values (%L, 5, 0, current_date)', :'venda'),
  '23514', null, 'parcela de valor zero é recusada');
select throws_ok(format(
  'insert into public.vendas (cliente_id, codigo, subtotal, total_descontos, total) values (%L, 50, 100, 10, 100)', :'cliente'),
  '23514', null, 'total diferente de subtotal - descontos é recusado');

-- Saldo do lote
select throws_ok(format('update public.lotes_estoque set quantidade_disponivel = -1 where id = %L', :'lote'),
  '23514', null, 'saldo negativo é recusado');
select throws_ok(format(
  'insert into public.lotes_estoque (lancamento_id, produto_id, numero_lote, quantidade, quantidade_disponivel, custo_unitario)
   values (%L, %L, 2, 3, 4, 10)', :'lanc', :'produto'),
  '23514', null, 'saldo maior que o recebido é recusado');

-- Durabilidade
select throws_ok(format(
  'insert into public.produtos (fornecedor_id, categoria_id, nome, preco_venda, durabilidade_dias) values (%L, %L, %L, 10, 10)', :'fornec', :'cat_prod', 'X'),
  '23514', null, 'durabilidade de 10 dias é recusada');
select lives_ok(format(
  'insert into public.produtos (fornecedor_id, categoria_id, nome, preco_venda, durabilidade_dias) values (%L, %L, %L, 10, 90)', :'fornec', :'cat_prod', 'Y'),
  'durabilidade de 90 dias é aceita');

-- Formas de pagamento
select throws_ok(format(
  'insert into public.pagamentos_parcela (parcela_id, valor, forma_pagamento) values (%L, 10, %L)', :'parcela', 'cheque'),
  '23514', null, 'forma de pagamento de parcela desconhecida é recusada');
select throws_ok(format(
  'insert into public.boletos (fornecedor_id, valor, data_vencimento, forma_pagamento) values (%L, 10, current_date, %L)', :'fornec', 'dinheiro'),
  '23514', null, 'forma de pagamento de boleto desconhecida é recusada');

-- Numeração única
select throws_ok(format(
  'insert into public.vendas (cliente_id, codigo, subtotal, total) values (%L, 1, 10, 10)', :'cliente'),
  '23505', null, 'código de venda repetido na mesma consultora é recusado');
select throws_ok(format(
  'insert into public.parcelas (venda_id, numero_parcela, valor, data_vencimento) values (%L, 1, 10, current_date)', :'venda'),
  '23505', null, 'número de parcela repetido na venda é recusado');
select throws_ok(format(
  'insert into public.lotes_estoque (lancamento_id, produto_id, numero_lote, quantidade, quantidade_disponivel, custo_unitario)
   values (%L, %L, 1, 1, 1, 10)', :'lanc', :'produto'),
  '23505', null, 'número de lote repetido no produto é recusado');
reset role;

select testes.popular(:'id_b');
select is((select codigo from public.vendas where consultora_id = :'id_b'), 1, 'mesmo código de venda em outra consultora é aceito');

select testes.autenticar_como(:'id_a');

-- Formatos da consultora
select throws_ok(format('update public.consultoras set whatsapp = %L where id = %L', '(11) 98765-4321', :'id_a'),
  '23514', null, 'WhatsApp com máscara é recusado');
select throws_ok(format('update public.consultoras set whatsapp = %L where id = %L', '119876', :'id_a'),
  '23514', null, 'WhatsApp curto é recusado');
select throws_ok(format('update public.consultoras set chave_pix = %L where id = %L', 'ana@email.com', :'id_a'),
  '23514', null, 'chave Pix sem tipo é recusada');
select lives_ok(format('update public.consultoras set chave_pix = %L, tipo_chave_pix = %L where id = %L', 'ana@email.com', 'email', :'id_a'),
  'chave Pix com tipo é aceita');

-- Cadastros em uso não são apagados
select throws_ok(format('delete from public.produtos where id = %L', :'produto'), '23503', null, 'produto vendido não é apagado');
select throws_ok(format('delete from public.fornecedores where id = %L', :'fornec'), '23503', null, 'fornecedor com boletos/produtos não é apagado');
select throws_ok(format('delete from public.clientes where id = %L', :'cliente'), '23503', null, 'cliente com venda não é apagada');
select throws_ok(format('delete from public.lotes_estoque where id = %L', :'lote'), '23503', null, 'lote com saída não é apagado');
select throws_ok(format('delete from public.categorias where id = %L', :'cat_prod'), '23503', null, 'categoria em uso não é apagada');

-- Cascade da venda
select lives_ok(format('delete from public.vendas where id = %L', :'venda'), 'venda é apagada');
select is(
  (select count(*)::int from public.itens_venda) + (select count(*)::int from public.parcelas)
  + (select count(*)::int from public.pagamentos_parcela) + (select count(*)::int from public.saidas_estoque),
  0, 'itens, parcelas, pagamentos e saídas da venda foram removidos');
reset role;

select * from finish();
rollback;
