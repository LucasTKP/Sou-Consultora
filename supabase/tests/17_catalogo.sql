-- Catálogo de produtos: leitura para consultoras logadas, nada para anon, escrita para ninguém.
begin;
\ir auxiliares/auxiliares.psql
select plan(15);

select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset

-- Dados criados pelo dono (superusuário do teste).
insert into public.catalogo_produtos (marca, codigo, nome, categoria, foto_caminho)
values ('MarcaTeste', 'T-1', 'Produto de teste', 'Maquiagem', 'marcateste/T-1.jpg');
insert into storage.objects (bucket_id, name) values ('catalogo', 'marcateste/T-1.jpg');

select is((select public from storage.buckets where id = 'catalogo'), false, 'bucket catalogo é privado');

-- Busca sem acento: a coluna `busca` é preenchida pelo trigger.
insert into public.catalogo_produtos (marca, codigo, nome) values ('MarcaBusca', 'T-2', 'Desodorante Colônia Ação');
select is((select busca from public.catalogo_produtos where codigo = 'T-2'), 'desodorante colonia acao t-2',
  'busca guarda nome e código sem acento e em minúsculas');
update public.catalogo_produtos set nome = 'Água Nova' where codigo = 'T-2';
select is((select busca from public.catalogo_produtos where codigo = 'T-2'), 'agua nova t-2',
  'busca acompanha a mudança de nome');
-- Consultora logada lê o catálogo e o arquivo, mas não escreve.
select testes.autenticar_como(:'id_a');
select is((select count(*)::int from public.catalogo_produtos where marca = 'MarcaTeste'), 1,
  'consultora lê o catálogo');
select is((select count(*)::int from storage.objects where bucket_id = 'catalogo' and name = 'marcateste/T-1.jpg'), 1,
  'consultora lê o arquivo do catálogo');
select throws_ok(
  $$ insert into public.catalogo_produtos (marca, codigo, nome) values ('X', '1', 'Y') $$,
  '42501', null, 'consultora não insere no catálogo');
select throws_ok(
  $$ update public.catalogo_produtos set nome = 'Hack' $$,
  '42501', null, 'consultora não altera o catálogo');
select throws_ok(
  $$ delete from public.catalogo_produtos $$,
  '42501', null, 'consultora não apaga do catálogo');
select throws_ok(
  $$ insert into storage.objects (bucket_id, name, owner_id) values ('catalogo', 'x/invasao.jpg', auth.uid()) $$,
  '42501', null, 'consultora não envia arquivo ao bucket do catálogo');
select is_empty(
  $$ with a as (delete from storage.objects where bucket_id = 'catalogo' returning 1) select * from a $$,
  'consultora não apaga arquivo do catálogo');
reset role;

-- Outra consultora vê o mesmo (catálogo é comum a todas).
select testes.autenticar_como(:'id_b');
select is((select count(*)::int from public.catalogo_produtos where marca = 'MarcaTeste'), 1,
  'a outra consultora também lê o catálogo');
reset role;

-- Anônimo não lê nada.
select testes.anonimo();
select throws_ok('select * from public.catalogo_produtos', '42501', null, 'anon não lê o catálogo');
select is((select count(*)::int from storage.objects where bucket_id = 'catalogo'), 0,
  'anon não lê arquivo do catálogo');
reset role;

select is((select c.relforcerowsecurity from pg_class c where c.oid = 'public.catalogo_produtos'::regclass),
  true, 'RLS forçado no catálogo');
select is((select count(*)::int from public.catalogo_produtos where marca = 'MarcaTeste'), 1,
  'dados do catálogo intactos');

select * from finish();
rollback;
