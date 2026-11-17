-- Ciclo de vida da conta (specs/conta-da-consultora).
begin;
\ir auxiliares/auxiliares.psql
select plan(14);

select testes.criar_usuario('a@teste.com') as id_a \gset
select testes.criar_usuario('outro@teste.com') as id_outro \gset
select testes.criar_consultora('b@teste.com') as id_b \gset

-- Registro vinculado ao login (agindo como A, como o app fará)
select testes.autenticar_como(:'id_a');
select throws_ok(
  format('insert into public.consultoras (id, nome, whatsapp) values (%L, %L, %L)', :'id_outro', 'Outra', '1'),
  '42501', null, 'registro com id de outro usuário é recusado');
select results_eq(
  $$ insert into public.consultoras (nome, whatsapp) values ('Ana', '11999990000') returning id $$,
  format('values (%L::uuid)', :'id_a'),
  'primeiro cadastro usa o id do login');
select throws_ok(
  $$ insert into public.consultoras (nome, whatsapp) values ('Ana', '11999990000') $$,
  '23505', null, 'segundo registro é recusado');

-- Categorias padrão
select is((select count(*)::int from public.categorias where tipo = 'produto'), 8, 'recebe 8 categorias de produto');
select is((select count(*)::int from public.categorias where tipo = 'servico'), 5, 'recebe 5 categorias de serviço');
select is((select bool_and(is_padrao and consultora_id = :'id_a') from public.categorias), true,
  'categorias copiadas são de A e marcadas como padrão');
update public.categorias set nome = 'Perfumes' where nome = 'Perfumaria';
reset role;
select is((select count(*)::int from public.categorias where consultora_id = :'id_b' and nome = 'Perfumaria'), 1,
  'renomear categoria de A não muda a de B');

select testes.popular(:'id_a');
select testes.popular(:'id_b');
select testes.linhas_da_consultora(:'id_b') as linhas_b \gset

-- A tenta apagar B diretamente: não existe caminho
select testes.autenticar_como(:'id_a');
select is_empty(format('delete from public.consultoras where id = %L returning 1', :'id_b'),
  'A não apaga o registro de B');
reset role;
select is((select count(*)::int from auth.users where id = :'id_b'), 1, 'login de B continua existindo');

-- Anônimo não apaga conta
select testes.anonimo();
select throws_ok('select public.apagar_minha_conta()', '42501', null, 'anônimo não chama apagar conta');
reset role;

-- A apaga a própria conta
select testes.autenticar_como(:'id_a');
select lives_ok('select public.apagar_minha_conta()', 'A apaga a própria conta');
reset role;
select is((select count(*)::int from auth.users where id = :'id_a'), 0, 'login de A deixou de existir');
select is(testes.linhas_da_consultora(:'id_a'), 0::bigint, 'nenhuma linha de A permanece');
select is(testes.linhas_da_consultora(:'id_b'), :'linhas_b'::bigint, 'todos os dados de B permanecem');

select * from finish();
rollback;
