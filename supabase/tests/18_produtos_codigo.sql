-- Código do produto único por consultora e marca; isolamento entre consultoras.
begin;
\ir auxiliares/auxiliares.psql
select plan(8);

select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset
select testes.popular(:'id_a');
select testes.popular(:'id_b');

select id as forn_a from public.fornecedores where consultora_id = :'id_a' limit 1 \gset
select id as cat_a from public.categorias where consultora_id = :'id_a' and tipo = 'produto' limit 1 \gset
select id as forn_b from public.fornecedores where consultora_id = :'id_b' limit 1 \gset
select id as cat_b from public.categorias where consultora_id = :'id_b' and tipo = 'produto' limit 1 \gset

select testes.autenticar_como(:'id_a');
select lives_ok(
  format($$ insert into public.produtos (fornecedor_id, categoria_id, nome, codigo, preco_venda) values (%L, %L, 'P1', 'X-1', 10) $$, :'forn_a', :'cat_a'),
  'primeiro produto com o código');
select throws_ok(
  format($$ insert into public.produtos (fornecedor_id, categoria_id, nome, codigo, preco_venda) values (%L, %L, 'P1 de novo', 'X-1', 10) $$, :'forn_a', :'cat_a'),
  '23505', null, 'mesmo código na mesma marca é recusado');
select throws_ok(
  format($$ insert into public.produtos (fornecedor_id, categoria_id, nome, codigo, preco_venda) values (%L, %L, 'P1 caixa', ' x-1 ', 10) $$, :'forn_a', :'cat_a'),
  '23505', null, 'a comparação ignora maiúsculas e espaços nas pontas');
select lives_ok(
  format($$ insert into public.produtos (fornecedor_id, categoria_id, nome, codigo, preco_venda) values (%L, %L, 'P2', 'X-2', 10) $$, :'forn_a', :'cat_a'),
  'outro código na mesma marca é permitido');
select lives_ok(
  format($$ insert into public.produtos (fornecedor_id, categoria_id, nome, preco_venda) values (%L, %L, 'Sem código 1', 10), (%L, %L, 'Sem código 2', 10) $$, :'forn_a', :'cat_a', :'forn_a', :'cat_a'),
  'produtos sem código não conflitam entre si');
select lives_ok(
  format($$ insert into public.produtos (fornecedor_id, categoria_id, nome, codigo, preco_venda) values (%L, %L, 'Vazio 1', '  ', 10), (%L, %L, 'Vazio 2', '', 10) $$, :'forn_a', :'cat_a', :'forn_a', :'cat_a'),
  'código em branco também é livre');
reset role;

-- Outra marca da mesma consultora aceita o mesmo código.
insert into public.fornecedores (consultora_id, nome) values (:'id_a', 'Outra Marca') returning id as forn_a2 \gset
select testes.autenticar_como(:'id_a');
select lives_ok(
  format($$ insert into public.produtos (fornecedor_id, categoria_id, nome, codigo, preco_venda) values (%L, %L, 'P1 outra marca', 'X-1', 10) $$, :'forn_a2', :'cat_a'),
  'o mesmo código em outra marca é permitido');
reset role;

-- Outra consultora pode usar o mesmo código.
select testes.autenticar_como(:'id_b');
select lives_ok(
  format($$ insert into public.produtos (fornecedor_id, categoria_id, nome, codigo, preco_venda) values (%L, %L, 'P1 da B', 'X-1', 10) $$, :'forn_b', :'cat_b'),
  'a outra consultora usa o mesmo código sem conflito');
reset role;

select * from finish();
rollback;
