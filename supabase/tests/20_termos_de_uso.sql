-- Aceite dos termos: data do banco, não apagável, isolado por consultora.
begin;
\ir auxiliares/auxiliares.psql
select plan(7);

select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset

select testes.autenticar_como(:'id_a');

update public.consultoras
   set termos_versao = '2026-11-26', termos_aceitos_em = '2000-01-01'
 where id = :'id_a';
select is(
  (select termos_aceitos_em from public.consultoras where id = :'id_a'),
  now(), 'a data do aceite é a do banco, não a enviada');

update public.consultoras
   set termos_versao = null, termos_aceitos_em = null
 where id = :'id_a';
select results_eq(
  format('select termos_versao, termos_aceitos_em from public.consultoras where id = %L', :'id_a'),
  $$ values ('2026-11-26'::text, now()) $$,
  'aceite gravado não é apagado');

select throws_ok(
  format('update public.consultoras set termos_versao = %L where id = %L', 'qualquer', :'id_a'),
  '23514', null, 'versão fora do formato é recusada');

-- Isolamento
select is_empty(
  format('select termos_versao from public.consultoras where id = %L', :'id_b'),
  'A não lê o aceite de B');
select is_empty(
  format('update public.consultoras set termos_versao = %L where id = %L returning 1', '2026-11-26', :'id_b'),
  'A não aceita no lugar de B');

reset role;
select is(
  (select termos_versao from public.consultoras where id = :'id_b'),
  null, 'cadastro de B permanece sem aceite');

select testes.anonimo();
select throws_ok('select termos_versao from public.consultoras', '42501', null, 'anon não lê os aceites');
reset role;

select * from finish();
rollback;
