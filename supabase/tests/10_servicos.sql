-- Serviços: categoria do tipo serviço, resumo_servicos e isolamento (specs/servicos).
begin;
\ir auxiliares/auxiliares.psql
select plan(12);

-- popular() cria, para cada consultora, o serviço "Sobrancelha" (R$ 60).
select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset
select testes.popular(:'id_a');
select testes.popular(:'id_b');

select id as servico_b from public.servicos where consultora_id = :'id_b' \gset
select id as unhas_a from public.categorias where consultora_id = :'id_a' and nome = 'Unhas' \gset
select id as perfumaria_a from public.categorias where consultora_id = :'id_a' and nome = 'Perfumaria' \gset

select testes.autenticar_como(:'id_a');

select throws_ok(
  format('insert into public.servicos (categoria_id, nome, preco_cobrado) values (%L, %L, 10)', :'perfumaria_a', 'Errado'),
  '23514', null, 'categoria de produto é recusada');
select throws_ok(
  format('insert into public.servicos (categoria_id, nome, preco_cobrado) values (%L, %L, -1)', :'unhas_a', 'Errado'),
  '23514', null, 'preço negativo é recusado');
select throws_ok(
  format('insert into public.servicos (categoria_id, nome, preco_cobrado, duracao_minutos) values (%L, %L, 10, 0)', :'unhas_a', 'Errado'),
  '23514', null, 'duração zero é recusada');
select throws_ok(
  format('insert into public.servicos (categoria_id, nome, preco_cobrado) values (%L, %L, 10)', :'unhas_a', '  '),
  '23514', null, 'nome vazio é recusado');
select lives_ok(
  format('insert into public.servicos (categoria_id, nome, preco_cobrado, custo_materiais, duracao_minutos) values (%L, %L, 65, 15, 90)', :'unhas_a', 'Manicure'),
  'serviço completo é aceito');

select results_eq(
  $$ select categoria_nome, preco_cobrado, custo_materiais, duracao_minutos from public.resumo_servicos where nome = 'Manicure' $$,
  $$ values ('Unhas', 65.00::numeric(12,2), 15.00::numeric(12,2), 90) $$,
  'resumo traz o serviço e o nome da categoria');

select is((select count(*)::int from public.resumo_servicos), 2, 'A vê só os próprios serviços');
select is_empty(format('select 1 from public.resumo_servicos where id = %L', :'servico_b'), 'A não vê o serviço de B');
select is_empty(format('update public.servicos set nome = %L where id = %L returning id', 'Invadido', :'servico_b'),
  'A não altera serviço de B');
select throws_ok(
  format('insert into storage.objects (bucket_id, name, owner_id) values (%L, %L, %L)', 'fotos', :'id_b' || '/servicos/1.jpg', :'id_a'),
  '42501', null, 'A não envia foto para a pasta de serviços de B');

reset role;
select is((select nome from public.servicos where id = :'servico_b'), 'Sobrancelha', 'serviço de B permanece igual');

select testes.anonimo();
select throws_ok('select count(*) from public.resumo_servicos', '42501', null, 'anon não lê o resumo');
reset role;

select * from finish();
rollback;
