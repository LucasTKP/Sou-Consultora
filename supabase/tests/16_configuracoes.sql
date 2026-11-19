-- Configurações: leitura para anon e authenticated, escrita para ninguém pelo app.
begin;
\ir auxiliares/auxiliares.psql
select plan(9);

select testes.criar_consultora('a@teste.com') as id_a \gset

-- Anônimo lê as duas chaves.
select testes.anonimo();
select results_eq(
  'select chave from public.configuracoes order by chave',
  $$ values ('versao_minima_android'::text), ('versao_minima_ios'::text) $$,
  'anon lê as versões mínimas');
select throws_ok(
  $$ insert into public.configuracoes (chave, valor) values ('x', '1') $$,
  '42501', null, 'anon não insere');
select throws_ok(
  $$ update public.configuracoes set valor = '9.9.9' $$,
  '42501', null, 'anon não atualiza');
reset role;

-- Consultora logada lê, mas não grava.
select testes.autenticar_como(:'id_a');
select is((select count(*)::int from public.configuracoes), 2, 'consultora lê as versões mínimas');
select throws_ok(
  $$ insert into public.configuracoes (chave, valor) values ('x', '1') $$,
  '42501', null, 'consultora não insere');
select throws_ok(
  $$ update public.configuracoes set valor = '9.9.9' $$,
  '42501', null, 'consultora não atualiza');
select throws_ok(
  $$ delete from public.configuracoes $$,
  '42501', null, 'consultora não apaga');
reset role;

select is((select valor from public.configuracoes where chave = 'versao_minima_ios'), '1.0.0',
  'valores continuam intactos');
select is(
  (select c.relforcerowsecurity from pg_class c where c.oid = 'public.configuracoes'::regclass),
  true, 'RLS forçado na tabela');

select * from finish();
rollback;
