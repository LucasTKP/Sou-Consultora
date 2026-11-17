-- Arquivos privados por consultora (specs/isolamento-de-dados — arquivos).
begin;
\ir auxiliares/auxiliares.psql
select plan(11);

select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset

select is((select bool_and(not public) from storage.buckets where id in ('fotos', 'comprovantes')), true,
  'buckets fotos e comprovantes são privados');

-- Arquivo de B criado pelo sistema
insert into storage.objects (bucket_id, name, owner_id) values ('fotos', :'id_b' || '/perfil.png', :'id_b');

select testes.autenticar_como(:'id_a');
select lives_ok(
  format('insert into storage.objects (bucket_id, name, owner_id) values (%L, %L, %L)', 'fotos', :'id_a' || '/perfil.png', :'id_a'),
  'A envia foto para a própria pasta');
select lives_ok(
  format('insert into storage.objects (bucket_id, name, owner_id) values (%L, %L, %L)', 'comprovantes', :'id_a' || '/boleto.pdf', :'id_a'),
  'A envia comprovante para a própria pasta');
select throws_ok(
  format('insert into storage.objects (bucket_id, name, owner_id) values (%L, %L, %L)', 'fotos', :'id_b' || '/invasao.png', :'id_a'),
  '42501', null, 'A não envia para a pasta de B');
select throws_ok(
  format('insert into storage.objects (bucket_id, name, owner_id) values (%L, %L, %L)', 'fotos', 'raiz.png', :'id_a'),
  '42501', null, 'A não envia fora de uma pasta própria');
select is((select count(*)::int from storage.objects where bucket_id in ('fotos', 'comprovantes')), 2,
  'A só enxerga os próprios arquivos');
select is_empty(format('update storage.objects set name = %L where name = %L returning 1', :'id_b' || '/x.png', :'id_b' || '/perfil.png'),
  'A não substitui arquivo de B');
select is_empty(format('select 1 from storage.objects where name = %L', :'id_b' || '/perfil.png'),
  'A não lê arquivo de B');
select is_empty(format('delete from storage.objects where name = %L returning 1', :'id_b' || '/perfil.png'),
  'A não apaga arquivo de B');
reset role;

select is((select count(*)::int from storage.objects where name = :'id_b' || '/perfil.png'), 1, 'arquivo de B permanece');

select testes.anonimo();
select is((select count(*)::int from storage.objects), 0, 'anônimo não lê nenhum arquivo');
reset role;

select * from finish();
rollback;
