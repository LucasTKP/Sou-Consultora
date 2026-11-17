-- Isolamento entre consultoras e contra anônimos (specs/isolamento-de-dados).
begin;
\ir auxiliares/auxiliares.psql
select plan(32);

select testes.criar_consultora('a@teste.com') as id_a \gset
select testes.criar_consultora('b@teste.com') as id_b \gset
select testes.popular(:'id_a');
select testes.popular(:'id_b');

-- Ids de registros de B, capturados antes de agir como A.
select id as cliente_b    from public.clientes      where consultora_id = :'id_b' \gset
select id as produto_b    from public.produtos      where consultora_id = :'id_b' \gset
select id as venda_b      from public.vendas        where consultora_id = :'id_b' \gset
select id as boleto_b     from public.boletos       where consultora_id = :'id_b' \gset
select id as lancamento_a from public.lancamentos_estoque where consultora_id = :'id_a' \gset
select id as cliente_a    from public.clientes      where consultora_id = :'id_a' \gset

select testes.autenticar_como(:'id_a');

-- Leitura: A vê exatamente as próprias linhas em cada tabela.
select is((select count(*)::int from public.consultoras),         1,  'A vê só o próprio registro de consultora');
select is((select count(*)::int from public.enderecos),           1,  'A vê só os próprios endereços');
select is((select count(*)::int from public.clientes),            1,  'A vê só as próprias clientes');
select is((select count(*)::int from public.fornecedores),        1,  'A vê só os próprios fornecedores');
select is((select count(*)::int from public.categorias),          13, 'A vê só as próprias categorias');
select is((select count(*)::int from public.produtos),            1,  'A vê só os próprios produtos');
select is((select count(*)::int from public.servicos),            1,  'A vê só os próprios serviços');
select is((select count(*)::int from public.lancamentos_estoque), 1,  'A vê só os próprios lançamentos');
select is((select count(*)::int from public.lotes_estoque),       1,  'A vê só os próprios lotes');
select is((select count(*)::int from public.vendas),              1,  'A vê só as próprias vendas');
select is((select count(*)::int from public.itens_venda),         1,  'A vê só os próprios itens de venda');
select is((select count(*)::int from public.parcelas),            1,  'A vê só as próprias parcelas');
select is((select count(*)::int from public.pagamentos_parcela),  1,  'A vê só os próprios pagamentos');
select is((select count(*)::int from public.saidas_estoque),      1,  'A vê só as próprias saídas');
select is((select count(*)::int from public.boletos),             1,  'A vê só os próprios boletos');
select is((select count(*)::int from public.categorias where consultora_id <> :'id_a'), 0, 'nenhuma categoria compartilhada');
select is_empty(format('select 1 from public.vendas where id = %L', :'venda_b'), 'A não acha venda de B pelo id');

-- Gravação em linhas de B: nada é afetado.
select is_empty(format('update public.clientes set nome = %L where id = %L returning 1', 'Invadido', :'cliente_b'),
  'A não altera cliente de B');
select is_empty(format('delete from public.boletos where id = %L returning 1', :'boleto_b'),
  'A não apaga boleto de B');
select is_empty(format('update public.consultoras set nome = %L where id = %L returning 1', 'Invadido', :'id_b'),
  'A não altera o registro de consultora de B');

-- Inserir em nome de B e transferir registro para B: recusado pelo RLS.
select throws_ok(
  format('insert into public.fornecedores (consultora_id, nome) values (%L, %L)', :'id_b', 'Marca X'),
  '42501', null, 'A não insere em nome de B');
select throws_ok(
  format('update public.clientes set consultora_id = %L where id = %L', :'id_b', :'cliente_a'),
  '42501', null, 'A não transfere registro para B');

-- Dona preenchida automaticamente.
select results_eq(
  $$ insert into public.fornecedores (nome) values ('Marca nova') returning consultora_id $$,
  format('values (%L::uuid)', :'id_a'),
  'insert sem consultora_id fica com A como dona');

-- Referências cruzadas: recusadas pela FK composta.
select throws_ok(
  format('insert into public.vendas (cliente_id, codigo, subtotal, total) values (%L, 99, 10, 10)', :'cliente_b'),
  '23503', null, 'A não cria venda para cliente de B');
select throws_ok(
  format('insert into public.lotes_estoque (lancamento_id, produto_id, numero_lote, quantidade, quantidade_disponivel, custo_unitario)
          values (%L, %L, 9, 1, 1, 10)', :'lancamento_a', :'produto_b'),
  '23503', null, 'A não cria lote com produto de B');

reset role;

-- B continua intacta.
select is((select nome from public.clientes where id = :'cliente_b'), 'Cliente', 'cliente de B permanece igual');
select is((select count(*)::int from public.boletos where id = :'boleto_b'), 1, 'boleto de B permanece');

-- Anônimo: sem acesso a nada.
select testes.anonimo();
select throws_ok('select count(*) from public.clientes', '42501', null, 'anon não lê clientes');
select throws_ok('select count(*) from public.consultoras', '42501', null, 'anon não lê consultoras');
select throws_ok('select count(*) from public.vendas', '42501', null, 'anon não lê vendas');
select throws_ok($$ insert into public.clientes (nome, whatsapp) values ('x', '1') $$, '42501', null, 'anon não grava clientes');
select throws_ok('select public.apagar_minha_conta()', '42501', null, 'anon não executa funções');
reset role;

select * from finish();
rollback;
