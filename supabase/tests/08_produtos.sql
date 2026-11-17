-- Produtos: regras de gravação, resumo_produtos e isolamento (specs/produtos).
begin;
\ir auxiliares/auxiliares.psql
select plan(20);

-- popular() cria, para cada consultora, o fornecedor "Marca" e o produto "Perfume"
-- com um lote de 3 unidades (2 disponíveis, sem validade).
select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset
select testes.popular(:'id_a');
select testes.popular(:'id_b');

select id as marca_a from public.fornecedores where consultora_id = :'id_a' \gset
select id as marca_b from public.fornecedores where consultora_id = :'id_b' \gset
select id as perfume_a from public.produtos where consultora_id = :'id_a' \gset
select id as perfume_b from public.produtos where consultora_id = :'id_b' \gset
select id as cat_a from public.categorias where consultora_id = :'id_a' and nome = 'Perfumaria' \gset
select id as cat_serv_a from public.categorias where consultora_id = :'id_a' and tipo = 'servico' limit 1 \gset
select id as lanc_a from public.lancamentos_estoque where consultora_id = :'id_a' \gset

select testes.autenticar_como(:'id_a');

-- ---------------------------------------------------------------------
-- Regras de gravação
-- ---------------------------------------------------------------------
select throws_ok(
  format('insert into public.produtos (fornecedor_id, categoria_id, nome, preco_venda) values (%L, %L, %L, 10)',
         :'marca_a', :'cat_serv_a', 'Esmalte'),
  '23514', null, 'categoria de serviço é recusada');
select throws_ok(
  format('insert into public.produtos (fornecedor_id, categoria_id, nome, preco_venda, durabilidade_dias) values (%L, %L, %L, 10, 200)',
         :'marca_a', :'cat_a', 'Colônia'),
  '23514', null, 'durabilidade fora de 30 a 180 é recusada');
select throws_ok(
  format('insert into public.produtos (fornecedor_id, categoria_id, nome, preco_venda) values (%L, %L, %L, -1)',
         :'marca_a', :'cat_a', 'Colônia'),
  '23514', null, 'preço negativo é recusado');
select throws_ok(
  format('insert into public.produtos (fornecedor_id, categoria_id, nome, preco_venda) values (%L, %L, %L, 10)',
         :'marca_a', :'cat_a', '  '),
  '23514', null, 'nome vazio é recusado');
select lives_ok(
  format('insert into public.produtos (fornecedor_id, categoria_id, nome, codigo, preco_venda) values (%L, %L, %L, %L, 89.9)',
         :'marca_a', :'cat_a', 'Batom', '   '),
  'produto sem durabilidade e com código em branco é aceito');
select is((select codigo from public.produtos where nome = 'Batom'), null, 'código em branco vira nulo');
select lives_ok(
  format('insert into public.produtos (fornecedor_id, categoria_id, nome, codigo, preco_venda, durabilidade_dias) values (%L, %L, %L, %L, 219.9, 60)',
         :'marca_a', :'cat_a', 'Kit Lily', ' BOT-74892 '),
  'produto completo é aceito');
select is((select codigo from public.produtos where nome = 'Kit Lily'), 'BOT-74892', 'código sem espaços nas pontas');

-- ---------------------------------------------------------------------
-- resumo_produtos
-- ---------------------------------------------------------------------
-- Kit Lily: lote de 3 (vence daqui a 30 dias), lote de 1 (vence daqui a 10 dias)
-- e um lote esgotado (venceria amanhã, mas não conta para a validade).
select id as lily from public.produtos where nome = 'Kit Lily' \gset
insert into public.lotes_estoque (lancamento_id, produto_id, numero_lote, quantidade, quantidade_disponivel, custo_unitario, validade)
values (:'lanc_a', :'lily', 1, 3, 3, 140, current_date + 30),
       (:'lanc_a', :'lily', 2, 1, 1, 140, current_date + 10),
       (:'lanc_a', :'lily', 3, 2, 0, 140, current_date + 1);

select results_eq(
  format('select qtd_disponivel, validade_atual, fornecedor_nome, fornecedor_ativo, categoria_nome
            from public.resumo_produtos where id = %L', :'lily'),
  format('values (4, %L::date, %L, true, %L)', current_date + 10, 'Marca', 'Perfumaria'),
  'estoque soma os lotes; validade atual ignora lote sem saldo; traz marca e categoria');
select results_eq(
  $$ select qtd_disponivel, validade_atual from public.resumo_produtos where nome = 'Batom' $$,
  $$ values (0, null::date) $$,
  'produto sem lotes tem estoque 0 e nenhuma validade');
select results_eq(
  $$ select preco_venda, durabilidade_dias, codigo from public.resumo_produtos where nome = 'Kit Lily' $$,
  $$ values (219.90::numeric(12,2), 60, 'BOT-74892') $$,
  'resumo traz os dados do produto');

-- ---------------------------------------------------------------------
-- Isolamento
-- ---------------------------------------------------------------------
select is((select count(*)::int from public.resumo_produtos), 3, 'A vê no resumo só os próprios produtos');
select is_empty(format('select 1 from public.resumo_produtos where id = %L', :'perfume_b'),
  'A não vê o produto de B no resumo');
select results_eq(
  format('select qtd_disponivel from public.resumo_produtos where id = %L', :'perfume_a'),
  $$ values (2) $$,
  'a quantidade de A não conta lotes de B');
select is_empty(format('update public.produtos set nome = %L where id = %L returning id', 'Invadido', :'perfume_b'),
  'A não altera produto de B');
select throws_ok(
  format('insert into public.produtos (fornecedor_id, categoria_id, nome, preco_venda) values (%L, %L, %L, 10)',
         :'marca_b', :'cat_a', 'Intruso'),
  '23503', null, 'A não usa a marca de B');
select throws_ok(
  format('insert into public.produtos (consultora_id, fornecedor_id, categoria_id, nome, preco_venda) values (%L, %L, %L, %L, 10)',
         :'id_b', :'marca_a', :'cat_a', 'Intruso'),
  null::char(5), null::text, 'A não grava produto como B');
select throws_ok(
  format('insert into storage.objects (bucket_id, name, owner_id) values (%L, %L, %L)', 'fotos', :'id_b' || '/produtos/1.jpg', :'id_a'),
  '42501', null, 'A não envia foto para a pasta de produtos de B');

reset role;
select is((select nome from public.produtos where id = :'perfume_b'), 'Perfume', 'produto de B permanece igual');

select testes.anonimo();
select throws_ok('select count(*) from public.resumo_produtos', '42501', null, 'anon não lê o resumo');
reset role;

select * from finish();
rollback;
