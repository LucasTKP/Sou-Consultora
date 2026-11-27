-- Estoque: lancar_estoque, apagar_lote, views e isolamento (specs/estoque).
begin;
\ir auxiliares/auxiliares.psql
select plan(28);

-- popular() cria, para cada consultora: fornecedor "Marca", produto "Perfume" com o
-- lote #1 (3 recebidas, 2 disponíveis) e uma venda à "Cliente" que consumiu 1 un dele.
select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset
select testes.popular(:'id_a');
select testes.popular(:'id_b');

select id as perfume_a from public.produtos where consultora_id = :'id_a' \gset
select id as perfume_b from public.produtos where consultora_id = :'id_b' \gset
select id as lote1_a from public.lotes_estoque where consultora_id = :'id_a' \gset
select id as lote1_b from public.lotes_estoque where consultora_id = :'id_b' \gset
select id as cat_a from public.categorias where consultora_id = :'id_a' and nome = 'Maquiagem' and tipo = 'produto' \gset
select (now() at time zone 'America/Sao_Paulo')::date as hoje \gset

select testes.autenticar_como(:'id_a');

insert into public.fornecedores (nome) values ('Natura');
select id as natura from public.fornecedores where nome = 'Natura' \gset
insert into public.produtos (fornecedor_id, categoria_id, nome, preco_venda)
values (:'natura', :'cat_a', 'Batom', 49.99);
select id as batom from public.produtos where nome = 'Batom' \gset

-- ---------------------------------------------------------------------
-- Lançar
-- ---------------------------------------------------------------------
select is(
  public.lancar_estoque(:'hoje'::date, jsonb_build_array(
    jsonb_build_object('produto_id', :'perfume_a', 'quantidade', 3, 'custo_unitario', 155, 'validade', :'hoje'::date + 100),
    jsonb_build_object('produto_id', :'batom', 'quantidade', 10, 'custo_unitario', 28.5))),
  2, 'compra com dois produtos grava dois lotes');

select is((select count(*)::int from public.lancamentos_estoque where data_compra = :'hoje'::date
            and id not in (select lancamento_id from public.lotes_estoque where id = :'lote1_a')),
  2, 'produtos de marcas diferentes viram um lançamento por marca');
select results_eq(
  format('select numero_lote, quantidade, quantidade_disponivel, custo_unitario from public.lotes_estoque
           where produto_id = %L order by numero_lote', :'perfume_a'),
  $$ values (1, 3, 2, 120.00::numeric(12,2)), (2, 3, 3, 155.00::numeric(12,2)) $$,
  'segundo lote do produto é o #2, com tudo disponível');
select results_eq(
  format('select numero_lote, fornecedor_nome, qtd_saidas from public.lotes_produtos where produto_id = %L', :'batom'),
  $$ values (1, 'Natura', 0) $$,
  'o lote é da marca do produto');
select is(
  (select l.validade from public.lotes_estoque l where l.produto_id = :'perfume_a' and l.numero_lote = 2),
  :'hoje'::date + 100, 'validade gravada no lote');

-- Tudo ou nada: o segundo item é inválido, nada é gravado.
select throws_ok(
  format('select public.lancar_estoque(%L::date, %L::jsonb)', :'hoje', jsonb_build_array(
    jsonb_build_object('produto_id', :'batom', 'quantidade', 1, 'custo_unitario', 10),
    jsonb_build_object('produto_id', :'perfume_a', 'quantidade', 0, 'custo_unitario', 10))),
  'SC400', 'A quantidade de cada produto precisa ser de pelo menos 1.', 'quantidade zero é recusada');
select is((select count(*)::int from public.lotes_estoque where produto_id = :'batom'), 1,
  'falha em um item não grava nenhum lote');

select throws_ok(format('select public.lancar_estoque(%L::date, %L::jsonb)', :'hoje', '[]'),
  'SC400', 'Adicione pelo menos um produto à compra.', 'compra sem itens é recusada');
select throws_ok(
  format('select public.lancar_estoque(%L::date, %L::jsonb)', :'hoje', jsonb_build_array(
    jsonb_build_object('produto_id', :'batom', 'quantidade', 1, 'custo_unitario', 10),
    jsonb_build_object('produto_id', :'batom', 'quantidade', 2, 'custo_unitario', 10))),
  'SC400', 'Cada produto pode aparecer uma vez só na compra.', 'produto repetido é recusado');
select throws_ok(
  format('select public.lancar_estoque(%L::date, %L::jsonb)', :'hoje'::date + 1, jsonb_build_array(
    jsonb_build_object('produto_id', :'batom', 'quantidade', 1, 'custo_unitario', 10))),
  'SC400', 'A data da compra não pode ser no futuro.', 'data futura é recusada');
select throws_ok(
  format('select public.lancar_estoque(%L::date, %L::jsonb)', :'hoje', jsonb_build_array(
    jsonb_build_object('produto_id', :'batom', 'quantidade', 1, 'custo_unitario', 10, 'validade', :'hoje'::date - 1))),
  'SC400', 'A validade do lote não pode ser antes da data da compra.', 'validade antes da compra é recusada');
select throws_ok(
  format('select public.lancar_estoque(%L::date, %L::jsonb)', :'hoje', jsonb_build_array(
    jsonb_build_object('produto_id', :'batom', 'quantidade', 1))),
  'SC400', 'Informe o custo unitário de cada produto.', 'custo ausente é recusado');

-- ---------------------------------------------------------------------
-- Views
-- ---------------------------------------------------------------------
select results_eq(
  format('select numero_lote, qtd_saidas, fornecedor_nome from public.lotes_produtos where id = %L', :'lote1_a'),
  $$ values (1, 1, 'Marca') $$,
  'lotes_produtos conta as unidades que saíram do lote');
select results_eq(
  format('select cliente_nome, quantidade, subtotal from public.saidas_produtos where produto_id = %L', :'perfume_a'),
  $$ values ('Cliente', 1, 200.00::numeric(12,2)) $$,
  'saidas_produtos traz a cliente, as unidades e o valor do item');
select is(
  (select qtd_disponivel from public.resumo_produtos where id = :'perfume_a'), 5,
  'resumo_produtos soma o lote novo');

-- ---------------------------------------------------------------------
-- Apagar lote
-- ---------------------------------------------------------------------
select id as lote_batom, lancamento_id as lanc_batom from public.lotes_estoque where produto_id = :'batom' \gset
select lives_ok(format('select public.apagar_lote(%L)', :'lote_batom'), 'lote sem saída é apagado');
select is_empty(format('select 1 from public.lotes_estoque where id = %L', :'lote_batom'), 'o lote some');
select is_empty(format('select 1 from public.lancamentos_estoque where id = %L', :'lanc_batom'),
  'o lançamento que ficou vazio some junto');
select throws_ok(format('select public.apagar_lote(%L)', :'lote1_a'),
  'SC400', 'Este lote já teve vendas e não pode ser apagado.', 'lote com saída é recusado');
select isnt_empty(format('select 1 from public.lotes_estoque where id = %L', :'lote1_a'), 'o lote com saída permanece');
select is(
  public.lancar_estoque(:'hoje'::date, jsonb_build_array(
    jsonb_build_object('produto_id', :'batom', 'quantidade', 2, 'custo_unitario', 28.5))),
  1, 'lança de novo depois de apagar');

-- ---------------------------------------------------------------------
-- Isolamento
-- ---------------------------------------------------------------------
select throws_ok(
  format('select public.lancar_estoque(%L::date, %L::jsonb)', :'hoje', jsonb_build_array(
    jsonb_build_object('produto_id', :'perfume_b', 'quantidade', 1, 'custo_unitario', 10))),
  'SC400', 'Produto não encontrado.', 'A não lança em produto de B');
select throws_ok(format('select public.apagar_lote(%L)', :'lote1_b'),
  'SC400', 'Lote não encontrado.', 'A não apaga lote de B');
select is_empty(format('select 1 from public.lotes_produtos where produto_id = %L', :'perfume_b'),
  'A não lê lotes de B');
select is_empty(format('select 1 from public.saidas_produtos where produto_id = %L', :'perfume_b'),
  'A não lê saídas de B');

reset role;
select is((select count(*)::int from public.lotes_estoque where produto_id = :'perfume_b'), 1,
  'estoque de B permanece igual');

select testes.anonimo();
select throws_ok('select count(*) from public.lotes_produtos', '42501', null, 'anon não lê os lotes');
select throws_ok(format('select public.apagar_lote(%L)', :'lote1_a'), '42501', null, 'anon não executa apagar_lote');
reset role;

select * from finish();
rollback;
