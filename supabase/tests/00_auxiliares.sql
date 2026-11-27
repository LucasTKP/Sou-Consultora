begin;
\ir auxiliares/auxiliares.psql
select plan(3);

select testes.criar_usuario('a@teste.com') as id_a \gset
select ok(:'id_a'::uuid is not null, 'cria usuário de teste');

select testes.autenticar_como(:'id_a');
select is(auth.uid(), :'id_a'::uuid, 'autentica como o usuário');
reset role;

select testes.anonimo();
select is(auth.uid(), null, 'anônimo não tem uid');
reset role;

select * from finish();
rollback;
