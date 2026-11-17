-- Fornecedores: formatos, nome único, resumo_fornecedores e isolamento (specs/fornecedores).
begin;
\ir auxiliares/auxiliares.psql
select plan(18);

-- popular() cria, para cada consultora, o fornecedor "Marca" com um boleto de 500 vencendo hoje.
select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset
select testes.popular(:'id_a');
select testes.popular(:'id_b');

select id as marca_a from public.fornecedores where consultora_id = :'id_a' \gset
select id as marca_b from public.fornecedores where consultora_id = :'id_b' \gset
select (now() at time zone 'America/Sao_Paulo')::date as hoje \gset

select testes.autenticar_como(:'id_a');

-- ---------------------------------------------------------------------
-- Integridade
-- ---------------------------------------------------------------------
select throws_ok($$ insert into public.fornecedores (nome, telefone) values ('Natura', '(11) 98765-4321') $$,
  '23514', null, 'telefone com máscara é recusado');
select throws_ok($$ insert into public.fornecedores (nome, telefone) values ('Natura', '119876') $$,
  '23514', null, 'telefone incompleto é recusado');
select throws_ok($$ insert into public.fornecedores (nome) values ('   ') $$,
  '23514', null, 'nome vazio é recusado');
select throws_ok($$ insert into public.fornecedores (nome) values (' MARCA ') $$,
  '23505', null, 'nome repetido (maiúsculas e espaços) na mesma consultora é recusado');
select lives_ok($$ insert into public.fornecedores (nome, telefone) values ('Natura', '11987654321') $$,
  'telefone só com dígitos é aceito');
select lives_ok($$ insert into public.fornecedores (nome, telefone) values ('Hinode', null) $$,
  'telefone vazio é aceito');

select testes.autenticar_como(:'id_b');
select lives_ok($$ insert into public.fornecedores (nome) values ('Natura') $$,
  'outra consultora pode ter fornecedor com o mesmo nome');
select testes.autenticar_como(:'id_a');

-- ---------------------------------------------------------------------
-- resumo_fornecedores
-- ---------------------------------------------------------------------
-- Natura: atrasado 100, vence hoje 50, futuro 70 (todos em aberto) e um pago de 200.
select id as natura from public.fornecedores where nome = 'Natura' \gset
insert into public.boletos (fornecedor_id, valor, data_vencimento, data_pagamento)
values (:'natura', 100, :'hoje'::date - 3, null),
       (:'natura', 50, :'hoje'::date, null),
       (:'natura', 70, :'hoje'::date + 10, null),
       (:'natura', 200, :'hoje'::date - 20, :'hoje'::date - 21);

select results_eq(
  format('select qtd_em_aberto, valor_em_aberto, qtd_atrasados, valor_atrasado, qtd_vence_hoje, qtd_pagos, valor_pagos
            from public.resumo_fornecedores where id = %L', :'natura'),
  $$ values (3, 220.00::numeric(12,2), 1, 100.00::numeric(12,2), 1, 1, 200.00::numeric(12,2)) $$,
  'em aberto inclui atrasados; vence hoje e pagos contados à parte');

select results_eq(
  $$ select qtd_em_aberto, valor_em_aberto, qtd_atrasados, valor_atrasado, qtd_vence_hoje, qtd_pagos, valor_pagos
       from public.resumo_fornecedores where nome = 'Hinode' $$,
  $$ values (0, 0::numeric(12,2), 0, 0::numeric(12,2), 0, 0, 0::numeric(12,2)) $$,
  'fornecedor sem boletos tem tudo zerado');

select results_eq(
  $$ select ativo, telefone from public.resumo_fornecedores where nome = 'Natura' $$,
  $$ values (true, '11987654321') $$,
  'resumo traz os dados do fornecedor (ativo por padrão)');

-- ---------------------------------------------------------------------
-- Isolamento
-- ---------------------------------------------------------------------
select is((select count(*)::int from public.resumo_fornecedores), 3, 'A vê no resumo só os próprios fornecedores');
select is_empty(format('select 1 from public.resumo_fornecedores where id = %L', :'marca_b'),
  'A não vê o fornecedor de B no resumo');
select results_eq(
  format('select qtd_em_aberto, valor_em_aberto from public.resumo_fornecedores where id = %L', :'marca_a'),
  $$ values (1, 500.00::numeric(12,2)) $$,
  'os números de A não contam boletos de B');
select is_empty(format('update public.fornecedores set nome = %L where id = %L returning id', 'Invadido', :'marca_b'),
  'A não altera fornecedor de B');
select throws_ok(format('insert into public.fornecedores (consultora_id, nome) values (%L, %L)', :'id_b', 'Intrusa'),
  '42501', null, 'A não grava fornecedor como B');

reset role;
select is((select nome from public.fornecedores where id = :'marca_b'), 'Marca', 'fornecedor de B permanece igual');

select testes.anonimo();
select throws_ok('select count(*) from public.resumo_fornecedores', '42501', null, 'anon não lê o resumo');
select throws_ok('select count(*) from public.fornecedores', '42501', null, 'anon não lê fornecedores');
reset role;

select * from finish();
rollback;
