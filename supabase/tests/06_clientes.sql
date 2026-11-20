-- Clientes: formatos, salvar_cliente, resumo_clientes e isolamento (specs/clientes).
begin;
\ir auxiliares/auxiliares.psql
select plan(27);

select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset
select testes.popular(:'id_a');
select testes.popular(:'id_b');

select id as cliente_b, endereco_id as endereco_b from public.clientes where consultora_id = :'id_b' \gset
select id as cliente_a from public.clientes where consultora_id = :'id_a' \gset
select (now() at time zone 'America/Sao_Paulo')::date as hoje \gset

select testes.autenticar_como(:'id_a');

-- ---------------------------------------------------------------------
-- salvar_cliente
-- ---------------------------------------------------------------------
select public.salvar_cliente(null, '  Mariana Souza ', '11987654321', '1990-05-10', '  ', null) as nova \gset
select is((select nome from public.clientes where id = :'nova'), 'Mariana Souza', 'cria cliente com o nome sem espaços nas pontas');
select is((select endereco_id from public.clientes where id = :'nova'), null, 'sem endereço, endereco_id fica nulo');
select is((select observacoes from public.clientes where id = :'nova'), null, 'observação em branco vira nulo');

select public.salvar_cliente(:'nova', 'Mariana Souza', '11987654321', null, 'Gosta de florais',
  '{"cep": "01001000", "rua": "Praça da Sé", "numero": "10", "uf": "sp", "bairro": " "}'::jsonb) as mesma \gset
select is(:'mesma'::uuid, :'nova'::uuid, 'editar devolve o mesmo id');
select is((select e.rua from public.clientes c join public.enderecos e on e.id = c.endereco_id where c.id = :'nova'),
  'Praça da Sé', 'editar cria e vincula o endereço');
select is((select e.uf::text from public.clientes c join public.enderecos e on e.id = c.endereco_id where c.id = :'nova'),
  'SP', 'UF é gravada em maiúsculas');
select is((select e.bairro from public.clientes c join public.enderecos e on e.id = c.endereco_id where c.id = :'nova'),
  null, 'campo de endereço em branco vira nulo');
select is((select observacoes from public.clientes where id = :'nova'), 'Gosta de florais', 'editar grava a observação');

select endereco_id as endereco_nova from public.clientes where id = :'nova' \gset
select public.salvar_cliente(:'nova', 'Mariana Souza', '11987654321', null, null,
  '{"cep": "01001000", "rua": "Rua Nova", "numero": "20"}'::jsonb);
select is((select endereco_id from public.clientes where id = :'nova'), :'endereco_nova'::uuid, 'editar o endereço reaproveita a mesma linha');

select public.salvar_cliente(:'nova', 'Mariana Souza', '11987654321', null, null, '{"rua": "  ", "numero": ""}'::jsonb);
select is((select endereco_id from public.clientes where id = :'nova'), null, 'endereço só com campos vazios remove o vínculo');
select is((select count(*)::int from public.enderecos where id = :'endereco_nova'), 0, 'o endereço removido não fica órfão');

-- ---------------------------------------------------------------------
-- Formatos
-- ---------------------------------------------------------------------
select throws_ok($$ select public.salvar_cliente(null, 'Ana', '(11) 98765-4321', null, null, null) $$,
  '23514', null, 'WhatsApp com máscara é recusado');
select throws_ok($$ select public.salvar_cliente(null, 'Ana', '119876', null, null, null) $$,
  '23514', null, 'WhatsApp curto é recusado');
select throws_ok(format('select public.salvar_cliente(null, %L, %L, %L, null, null)', 'Ana', '11987654321', (:'hoje'::date + 2)),
  '23514', null, 'nascimento no futuro é recusado');
select throws_ok($$ select public.salvar_cliente(null, '   ', '11987654321', null, null, null) $$,
  '23514', null, 'nome vazio é recusado');
select throws_ok($$ select public.salvar_cliente(null, 'Ana', '11987654321', null, null, '{"rua": "R", "uf": "S1"}'::jsonb) $$,
  '23514', null, 'UF fora do padrão é recusada');

-- ---------------------------------------------------------------------
-- resumo_clientes
-- ---------------------------------------------------------------------
-- Venda 1 (300): parcela vencida de 100 com 30 pagos, parcela de 100 vencendo hoje, parcela futura de 100.
-- Venda 2 (50): parcela única paga por inteiro.
insert into public.vendas (id, cliente_id, codigo, subtotal, total, data_venda)
values ('00000000-0000-0000-0000-0000000000a1', :'nova', 10, 300, 300, now() - interval '10 days'),
       ('00000000-0000-0000-0000-0000000000a2', :'nova', 11, 50, 50, now() - interval '2 days');
insert into public.parcelas (id, venda_id, numero_parcela, valor, data_vencimento)
values ('00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-0000000000a1', 1, 100, :'hoje'::date - 5),
       ('00000000-0000-0000-0000-0000000000b2', '00000000-0000-0000-0000-0000000000a1', 2, 100, :'hoje'::date),
       ('00000000-0000-0000-0000-0000000000b3', '00000000-0000-0000-0000-0000000000a1', 3, 100, :'hoje'::date + 30),
       ('00000000-0000-0000-0000-0000000000b4', '00000000-0000-0000-0000-0000000000a2', 1, 50, :'hoje'::date - 1);
insert into public.pagamentos_parcela (parcela_id, valor, forma_pagamento)
values ('00000000-0000-0000-0000-0000000000b1', 30, 'pix'),
       ('00000000-0000-0000-0000-0000000000b4', 50, 'dinheiro');

select results_eq(
  format('select qtd_compras, total_compras, saldo_devedor, valor_atrasado, valor_vence_hoje, qtd_atrasadas
            from public.resumo_clientes where id = %L', :'nova'),
  $$ values (2, 350.00::numeric(12,2), 270.00::numeric(12,2), 70.00::numeric(12,2), 100.00::numeric(12,2), 1) $$,
  'resumo soma compras, saldo, atrasado (com pagamento parcial), vence hoje e conta as atrasadas; parcela quitada não conta');

select public.salvar_cliente(null, 'Sem Compras', '11911112222', null, null, null) as sem_compras \gset
select results_eq(
  format('select qtd_compras, total_compras, saldo_devedor, valor_atrasado, valor_vence_hoje, qtd_atrasadas, ultima_compra is null
            from public.resumo_clientes where id = %L', :'sem_compras'),
  $$ values (0, 0::numeric(12,2), 0::numeric(12,2), 0::numeric(12,2), 0::numeric(12,2), 0, true) $$,
  'cliente sem vendas tem tudo zerado e sem última compra');

-- ---------------------------------------------------------------------
-- Isolamento
-- ---------------------------------------------------------------------
select is((select count(*)::int from public.resumo_clientes), 3, 'A vê no resumo só as próprias clientes');
select is_empty(format('select 1 from public.resumo_clientes where id = %L', :'cliente_b'),
  'A não vê o resumo da cliente de B');
select throws_ok(format('select public.salvar_cliente(%L, %L, %L, null, null, null)', :'cliente_b', 'Invadido', '11987654321'),
  'P0002', null, 'A não edita cliente de B pela função');
select throws_ok(format('update public.clientes set endereco_id = %L where id = %L', :'endereco_b', :'cliente_a'),
  '23503', null, 'A não vincula endereço de B à própria cliente');

reset role;
select is((select nome from public.clientes where id = :'cliente_b'), 'Cliente', 'cliente de B permanece igual');
select isnt((select endereco_id from public.clientes where id = :'cliente_b'), null, 'endereço de B continua vinculado');

select testes.autenticar_como(:'id_b');
select is((select count(*)::int from public.resumo_clientes), 1, 'B vê no resumo só a própria cliente');
reset role;

select testes.anonimo();
select throws_ok('select count(*) from public.resumo_clientes', '42501', null, 'anon não lê o resumo');
select throws_ok($$ select public.salvar_cliente(null, 'x', '11987654321', null, null, null) $$,
  '42501', null, 'anon não executa salvar_cliente');
reset role;

select * from finish();
rollback;
