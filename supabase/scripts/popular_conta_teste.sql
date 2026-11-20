-- Popula UMA conta com muitos dados para teste (clientes, produtos, estoque,
-- vendas, parcelas, pagamentos e boletos). NÃO é migração: rode à mão no
-- SQL Editor do Supabase (papel postgres, que ignora o RLS — por isso o
-- consultora_id vai explícito) ou com psql no banco local.
--
-- Tudo que este script cria leva o marcador '[seed]' (observacoes, ou
-- referencia nos endereços). `limpar_conta_teste.sql` apaga só isso.
--
-- Pré-requisitos: a consultora já existe (concluiu o cadastro no app) e tem as
-- categorias padrão. Não mexe em nada que já exista na conta.
-- Rode UMA vez; para repetir, limpe antes.

do $seed$
declare
  -- ===== Parâmetros ==================================================
  v_id         uuid := 'a9e1f1b3-4b5d-4189-96a5-5f50ba472d57';
  n_fornec     int  := 12;
  n_clientes   int  := 300;
  n_produtos   int  := 150;
  n_servicos   int  := 25;
  n_vendas     int  := 1500;
  n_boletos    int  := 80;
  -- ====================================================================
  v_hoje       date := (now() at time zone 'America/Sao_Paulo')::date;
  v_base_cod   int;
  v_cat_prod   uuid[];
  v_cat_serv   uuid[];
  v_forn       uuid[];
  v_cli        uuid[];
  v_prod       uuid[];
  v_serv       uuid[];
  n_resultado  record;
begin
  if not exists (select 1 from public.consultoras where id = v_id) then
    raise exception 'Consultora % não encontrada. Conclua o cadastro no app antes.', v_id;
  end if;
  if exists (select 1 from public.clientes where consultora_id = v_id and observacoes like '[seed]%') then
    raise exception 'Esta conta já tem dados seed. Rode limpar_conta_teste.sql antes.';
  end if;

  select coalesce(array_agg(id), '{}') into v_cat_prod
    from public.categorias where consultora_id = v_id and tipo = 'produto';
  select coalesce(array_agg(id), '{}') into v_cat_serv
    from public.categorias where consultora_id = v_id and tipo = 'servico';
  if cardinality(v_cat_prod) = 0 or cardinality(v_cat_serv) = 0 then
    raise exception 'A conta precisa de pelo menos uma categoria de produto e uma de serviço.';
  end if;

  perform setseed(0.42);

  -- ------------------------------------------------------------------
  -- Fornecedores (marcas)
  -- ------------------------------------------------------------------
  create temp table t_forn on commit drop as
  select gen_random_uuid() as id, g as n
    from generate_series(1, n_fornec) g;

  insert into public.fornecedores (id, consultora_id, nome, ramo, contato, telefone, observacoes, ativo)
  select f.id, v_id,
         case
           when f.n = 3 then 'Distribuidora de Cosméticos e Perfumaria Nacional e Importada Ltda. Filial Sul (teste)'
           else (array['Natura','Avon','O Boticário','Eudora','Mary Kay','Jequiti','Tupperware',
                       'Hinode','Racco','Lacoste Distribuição','Granado','Quem Disse, Berenice?'])[1 + (f.n - 1) % 12]
                || case when f.n > 12 then ' ' || f.n else '' end
                || ' (teste)'
         end,
         case when f.n % 3 = 0 then null else 'Cosméticos' end,
         case when f.n % 4 = 0 then null else 'Atendimento ' || f.n end,
         case when f.n % 5 = 0 then null else '11' || '9' || lpad((floor(random() * 100000000))::text, 8, '0') end,
         '[seed]',
         f.n <> 7
    from t_forn f;

  select array_agg(id) into v_forn from t_forn;

  -- ------------------------------------------------------------------
  -- Clientes (+ endereços para ~70%)
  -- ------------------------------------------------------------------
  create temp table t_cli on commit drop as
  select gen_random_uuid() as id, gen_random_uuid() as endereco_id, g as n
    from generate_series(1, n_clientes) g;

  insert into public.enderecos (id, consultora_id, cep, rua, numero, complemento, bairro, cidade, uf, referencia)
  select c.endereco_id, v_id,
         lpad((floor(random() * 99999999))::text, 8, '0'),
         (array['Rua das Flores','Avenida Brasil','Rua Sete de Setembro','Travessa do Comércio',
                'Rua Doutor João Batista de Almeida Prado Filho'])[1 + floor(random() * 5)::int],
         (1 + floor(random() * 2000))::text,
         case when random() < 0.3 then 'Apto ' || (1 + floor(random() * 300)) end,
         (array['Centro','Jardim América','Vila Nova','São José','Santa Efigênia'])[1 + floor(random() * 5)::int],
         (array['São Paulo','Campinas','Belo Horizonte','Curitiba','Recife'])[1 + floor(random() * 5)::int],
         (array['SP','SP','MG','PR','PE'])[1 + floor(random() * 5)::int],
         '[seed]'
    from t_cli c
   where c.n % 10 < 7;

  insert into public.clientes (id, consultora_id, endereco_id, nome, whatsapp, data_nascimento, observacoes)
  select c.id, v_id,
         case when c.n % 10 < 7 then c.endereco_id end,
         case
           when c.n % 37 = 0 then 'Maria Aparecida da Conceição de Albuquerque e Vasconcelos Santos Pereira Neto'
           when c.n % 29 = 0 then 'Joana D''Ávila-Müller'
           when c.n % 41 = 0 then 'Bia'
           else (array['Ana','Maria','Juliana','Fernanda','Patrícia','Camila','Aline','Larissa','Beatriz','Renata',
                       'Carla','Vanessa','Débora','Luciana','Tatiane','Gabriela','Priscila','Mônica','Sandra','Cláudia',
                       'Simone','Eliane','Rosana','Helena','Isabela','Letícia','Raquel','Viviane','Adriana','Bruna'])
                  [1 + floor(random() * 30)::int]
                || ' ' ||
                (array['Silva','Santos','Oliveira','Souza','Rodrigues','Ferreira','Alves','Pereira','Lima','Gomes',
                       'Costa','Ribeiro','Martins','Carvalho','Almeida','Lopes','Soares','Fernandes','Vieira','Barbosa',
                       'Rocha','Dias','Nascimento','Andrade','Moreira','Nunes','Marques','Machado','Mendes','Freitas'])
                  [1 + floor(random() * 30)::int]
         end,
         '11' || '9' || lpad((floor(random() * 100000000))::text, 8, '0'),
         case
           when c.n % 15 = 0 then v_hoje - (28 * 365 + floor(random() * 6000))::int + (floor(random() * 7) - 3)::int
           when random() < 0.6 then v_hoje - (18 * 365 + floor(random() * 15000))::int
         end,
         '[seed]' || case when c.n % 9 = 0 then ' Prefere contato à tarde. Gosta de fragrâncias florais e cítricas, evita amadeirados.' else '' end
    from t_cli c;

  select array_agg(id) into v_cli from t_cli;

  -- ------------------------------------------------------------------
  -- Produtos
  -- ------------------------------------------------------------------
  create temp table t_prod on commit drop as
  select gen_random_uuid() as id, g as n,
         v_forn[1 + floor(random() * n_fornec)::int] as fornecedor_id,
         v_cat_prod[1 + floor(random() * cardinality(v_cat_prod))::int] as categoria_id,
         case g
           when 1 then 0.01::numeric
           when 2 then 49999.90::numeric
           else round((10 + random() * 390)::numeric, 2)
         end as preco_venda
    from generate_series(1, n_produtos) g;

  alter table t_prod add column preco_custo numeric(12, 2);
  update t_prod
     set preco_custo = case
           when n % 11 = 0 then null
           when n = 1 then 0.01
           else round((preco_venda * (0.35 + random() * 0.4))::numeric, 2)
         end;

  insert into public.produtos (id, consultora_id, fornecedor_id, categoria_id, nome, codigo,
                               preco_venda, preco_custo, durabilidade_dias, observacoes)
  select p.id, v_id, p.fornecedor_id, p.categoria_id,
         case
           when p.n % 19 = 0 then 'Kit Presente Edição Limitada Coleção Primavera Verão com Perfume Hidratante Sabonete e Necessaire'
           else (array['Perfume','Hidratante','Batom','Base líquida','Máscara de cílios','Shampoo','Condicionador',
                       'Sabonete líquido','Creme para as mãos','Protetor solar','Desodorante colônia','Esmalte'])
                  [1 + floor(random() * 12)::int]
                || ' ' ||
                (array['Floratta','Essencial','Ekos','Lily','Mary Kay','Nativa SPA','Malbec','Humor','Tododia','Faces',
                       'Cuide-se Bem','Kriska'])[1 + floor(random() * 12)::int]
                || ' ' || (array['30ml','50ml','75ml','100ml','200ml','400ml','Rosa','Nude','Intenso'])[1 + floor(random() * 9)::int]
                || ' #' || p.n
         end,
         case when p.n % 5 = 0 then null else 'SD' || lpad(p.n::text, 5, '0') end,
         p.preco_venda, p.preco_custo,
         case when random() < 0.5 then 30 + floor(random() * 151)::int end,
         '[seed]'
    from t_prod p;

  select array_agg(id order by n) into v_prod from t_prod;

  -- ------------------------------------------------------------------
  -- Serviços
  -- ------------------------------------------------------------------
  create temp table t_serv on commit drop as
  select gen_random_uuid() as id, g as n,
         round((20 + random() * 580)::numeric, 2) as preco_cobrado
    from generate_series(1, n_servicos) g;

  insert into public.servicos (id, consultora_id, categoria_id, nome, preco_cobrado, custo_materiais,
                               duracao_minutos, retorno_dias, observacoes)
  select s.id, v_id,
         v_cat_serv[1 + floor(random() * cardinality(v_cat_serv))::int],
         (array['Manicure','Pedicure','Design de sobrancelha','Limpeza de pele','Maquiagem social','Hidratação capilar',
                'Depilação com cera','Alongamento de unhas','Penteado','Micropigmentação'])[1 + floor(random() * 10)::int]
           || ' ' || s.n,
         s.preco_cobrado,
         case when s.n % 4 = 0 then null else round((s.preco_cobrado * (0.05 + random() * 0.3))::numeric, 2) end,
         case when s.n % 3 = 0 then null else 15 + floor(random() * 226)::int end,
         case when s.n % 2 = 0 then null else 7 + floor(random() * 54)::int end,
         '[seed]'
    from t_serv s;

  select array_agg(id order by n) into v_serv from t_serv;

  -- ------------------------------------------------------------------
  -- Estoque: um lançamento por marca (compra antiga); lote 1 em todo produto,
  -- lote 2 em ~30%. A quantidade do lote 1 é ajustada depois das saídas.
  -- ------------------------------------------------------------------
  create temp table t_lanc on commit drop as
  select gen_random_uuid() as id, f.id as fornecedor_id, 1 as tipo from t_forn f
  union all
  select gen_random_uuid(), f.id, 2 from t_forn f;

  insert into public.lancamentos_estoque (id, consultora_id, fornecedor_id, data_compra)
  select l.id, v_id, l.fornecedor_id,
         case l.tipo when 1 then v_hoje - 380 else v_hoje - 120 end
    from t_lanc l;

  create temp table t_lote1 on commit drop as
  select gen_random_uuid() as id, p.id as produto_id, p.n from t_prod p;

  insert into public.lotes_estoque (id, consultora_id, lancamento_id, produto_id, numero_lote,
                                    quantidade, quantidade_disponivel, custo_unitario, validade)
  select l.id, v_id,
         (select la.id from t_lanc la where la.fornecedor_id = p.fornecedor_id and la.tipo = 1),
         p.id, 1, 1, 1,
         coalesce(p.preco_custo, round((p.preco_venda * 0.5)::numeric, 2)),
         case when l.n % 5 < 2 then v_hoje + (floor(random() * 560) - 60)::int end
    from t_lote1 l join t_prod p on p.id = l.produto_id;

  insert into public.lotes_estoque (consultora_id, lancamento_id, produto_id, numero_lote,
                                    quantidade, quantidade_disponivel, custo_unitario, validade)
  select v_id,
         (select la.id from t_lanc la where la.fornecedor_id = p.fornecedor_id and la.tipo = 2),
         p.id, 2, q.q, q.q,
         coalesce(p.preco_custo, round((p.preco_venda * 0.5)::numeric, 2)),
         case when p.n % 2 = 0 then v_hoje + (floor(random() * 400) - 20)::int end
    from t_prod p
    cross join lateral (select 1 + floor(random() * 30)::int as q) q
   where p.n % 10 < 3;

  -- ------------------------------------------------------------------
  -- Vendas
  -- ------------------------------------------------------------------
  select ultimo_codigo_venda into v_base_cod from public.consultoras where id = v_id;

  create temp table t_venda on commit drop as
  with base as (
    select gen_random_uuid() as id, g as n,
           v_cli[1 + floor(power(random(), 2) * n_clientes)::int] as cliente_id,
           floor(power(random(), 1.4) * 340)::int as dias
      from generate_series(1, n_vendas) g
  )
  select id, n, cliente_id,
         -- Um mês inteiro sem venda (dias 150 a 180) para o gráfico ter buraco.
         case when dias between 150 and 180 then dias + 31 else dias end as dias_atras,
         1 + floor(random() * 5)::int as n_itens
    from base;

  insert into public.vendas (id, consultora_id, cliente_id, codigo, data_venda,
                             subtotal, total_descontos, total, observacoes)
  select v.id, v_id, v.cliente_id,
         v_base_cod + row_number() over (order by v.dias_atras desc, v.n),
         case
           when v.dias_atras = 0 then now() - (random() * interval '2 hours')
           else ((v_hoje - v.dias_atras)::timestamp
                 + interval '8 hours' + random() * interval '11 hours') at time zone 'America/Sao_Paulo'
         end,
         0, 0, 0, '[seed]'
    from t_venda v;

  update public.consultoras
     set ultimo_codigo_venda = v_base_cod + n_vendas
   where id = v_id;

  create temp table t_item on commit drop as
  with cand as (
    select v.id as venda_id, k,
           (random() < 0.85) as eh_produto,
           v_prod[1 + floor(random() * n_produtos)::int] as pid,
           v_serv[1 + floor(random() * n_servicos)::int] as sid,
           case when random() < 0.05 then 5 + floor(random() * 8)::int
                else 1 + floor(random() * 3)::int end as qtd,
           random() as r_desc, random() as r_pct, random() as r_baixa
      from t_venda v
      cross join lateral generate_series(1, v.n_itens) k
  ), unicos as (
    select distinct on (venda_id, case when eh_produto then pid else sid end) *
      from cand
     order by venda_id, case when eh_produto then pid else sid end
  )
  select gen_random_uuid() as id, u.venda_id,
         case when u.eh_produto then u.pid end as produto_id,
         case when not u.eh_produto then u.sid end as servico_id,
         u.qtd as quantidade,
         case when u.eh_produto then p.preco_venda else s.preco_cobrado end as preco_unitario,
         case when u.eh_produto then coalesce(p.preco_custo, 0) else 0 end as custo_unitario,
         u.r_desc, u.r_pct,
         (u.eh_produto and u.r_baixa < 0.9) as baixar_estoque
    from unicos u
    left join t_prod p on u.eh_produto and p.id = u.pid
    left join t_serv s on not u.eh_produto and s.id = u.sid;

  alter table t_item add column desconto numeric(12, 2);
  update t_item
     set desconto = case
           when r_desc < 0.30 then round((preco_unitario * quantidade * r_pct * 0.4)::numeric, 2)
           else 0
         end;

  insert into public.itens_venda (id, consultora_id, venda_id, produto_id, servico_id, quantidade,
                                  preco_unitario, custo_unitario, desconto, subtotal, baixar_estoque)
  select i.id, v_id, i.venda_id, i.produto_id, i.servico_id, i.quantidade,
         i.preco_unitario, i.custo_unitario, i.desconto,
         i.preco_unitario * i.quantidade - i.desconto, i.baixar_estoque
    from t_item i;

  update public.vendas v
     set subtotal        = x.bruto,
         total_descontos = x.desc_total,
         total           = x.bruto - x.desc_total
    from (select i.venda_id,
                 sum(i.preco_unitario * i.quantidade) as bruto,
                 sum(i.desconto) as desc_total
            from t_item i group by i.venda_id) x
   where v.id = x.venda_id and v.consultora_id = v_id;

  -- Saídas de estoque (tudo no lote 1) e ajuste da quantidade dos lotes.
  insert into public.saidas_estoque (consultora_id, item_venda_id, lote_id, quantidade)
  select v_id, i.id, l.id, i.quantidade
    from t_item i join t_lote1 l on l.produto_id = i.produto_id
   where i.baixar_estoque;

  update public.lotes_estoque le
     set quantidade = greatest(s.saiu + s.extra, 1),
         quantidade_disponivel = greatest(s.saiu + s.extra, 1) - s.saiu
    from (select l.id,
                 coalesce((select sum(i.quantidade) from t_item i
                            where i.produto_id = l.produto_id and i.baixar_estoque), 0) as saiu,
                 case when l.n % 13 = 0 then 0 else 1 + floor(random() * 40)::int end as extra
            from t_lote1 l) s
   where le.id = s.id and le.consultora_id = v_id;

  -- ------------------------------------------------------------------
  -- Parcelas
  -- ------------------------------------------------------------------
  create temp table t_parcela on commit drop as
  with plano as (
    select v.id as venda_id, ve.total, ve.data_venda::date as data_v,
           case
             when ve.total < 12 then 1
             else (array[1,1,1,1,1,2,2,3,3,4,6,10,12])[1 + floor(random() * 13)::int]
           end as np,
           (random() < 0.3) as entrada
      from t_venda v join public.vendas ve on ve.id = v.id
  )
  select gen_random_uuid() as id, p.venda_id, k as numero,
         case when k < p.np then round(p.total / p.np, 2)
              else p.total - round(p.total / p.np, 2) * (p.np - 1) end as valor,
         p.data_v + (k - 1) * 30 + case when p.entrada then 0 else 30 end as vencimento,
         p.data_v
    from plano p cross join lateral generate_series(1, p.np) k;

  insert into public.parcelas (id, consultora_id, venda_id, numero_parcela, valor, data_vencimento)
  select id, v_id, venda_id, numero, valor, vencimento from t_parcela;

  -- Pagamentos: vencidas ~60% pagas, 15% parciais, 25% em aberto; a vencer ~10% antecipadas.
  create temp table t_pag on commit drop as
  select p.id as parcela_id, p.valor, p.data_v, p.vencimento,
         random() as r, random() as r_dia, random() as r_forma, random() as r_pct,
         (random() < 0.3) as duas_vezes
    from t_parcela p;

  insert into public.pagamentos_parcela (consultora_id, parcela_id, valor, forma_pagamento, data_pagamento)
  select v_id, g.parcela_id, g.valor_pago,
         (array['pix','cartao','dinheiro'])[1 + floor(g.r_forma * 3)::int],
         g.quando
    from (
      select t.parcela_id, t.r_forma,
             case when t.r < 0.60 or (t.vencimento >= v_hoje and t.r < 0.10) then t.valor
                  else round((t.valor * (0.2 + t.r_pct * 0.6))::numeric, 2) end as valor_pago,
             (least(greatest(t.data_v, t.vencimento - 5 + floor(t.r_dia * 9)::int), v_hoje)::timestamp
                + interval '12 hours') at time zone 'America/Sao_Paulo' as quando
        from t_pag t
       where (t.vencimento < v_hoje and (t.r < 0.60 or (t.r < 0.75 and t.valor >= 1)))
          or (t.vencimento >= v_hoje and t.r < 0.10 and t.data_v <= v_hoje)
    ) g
   where g.valor_pago > 0;

  -- Parciais com segundo pagamento (soma sempre abaixo do valor da parcela).
  insert into public.pagamentos_parcela (consultora_id, parcela_id, valor, forma_pagamento, data_pagamento)
  select v_id, t.parcela_id, round(t.valor * 0.15, 2), 'pix',
         (least(t.vencimento + 3, v_hoje)::timestamp + interval '15 hours') at time zone 'America/Sao_Paulo'
    from t_pag t
   where t.vencimento < v_hoje and t.r >= 0.60 and t.r < 0.75 and t.valor >= 1 and t.duas_vezes
     and round(t.valor * 0.15, 2) > 0
     and round((t.valor * (0.2 + t.r_pct * 0.6))::numeric, 2) + round(t.valor * 0.15, 2) < t.valor;

  -- ------------------------------------------------------------------
  -- Boletos (a pagar)
  -- ------------------------------------------------------------------
  insert into public.boletos (consultora_id, fornecedor_id, valor, data_vencimento, forma_pagamento,
                              observacoes, data_pagamento)
  select v_id, b.fornecedor_id, b.valor, b.vencimento,
         case when b.pago or b.r_forma < 0.5 then (array['pix','boleto','transferencia'])[1 + floor(b.r_forma * 6)::int % 3] end,
         '[seed]' || case when b.n % 7 = 0 then ' Parcela da compra de reposição do mês, conferir nota fiscal.' else '' end,
         case when b.pago then least(b.vencimento + (floor(b.r_dia * 4) - 3)::int, v_hoje) end
    from (
      select g as n, v_forn[1 + floor(random() * n_fornec)::int] as fornecedor_id,
             round((20 + power(random(), 3) * 7980)::numeric, 2) as valor,
             v_hoje + (floor(random() * 210) - 120)::int as vencimento,
             random() as r_forma, random() as r_dia, random() as r_pago
        from generate_series(1, n_boletos) g
    ) x
    cross join lateral (
      select x.n, x.fornecedor_id, x.valor, x.vencimento, x.r_forma, x.r_dia,
             case when x.vencimento < v_hoje then x.r_pago < 0.7 else x.r_pago < 0.05 end as pago
    ) b;

  -- ------------------------------------------------------------------
  select (select count(*) from public.clientes   where consultora_id = v_id and observacoes like '[seed]%') as clientes,
         (select count(*) from public.produtos   where consultora_id = v_id and observacoes like '[seed]%') as produtos,
         (select count(*) from public.vendas     where consultora_id = v_id and observacoes like '[seed]%') as vendas,
         (select count(*) from public.parcelas   p join public.vendas v on v.id = p.venda_id
           where p.consultora_id = v_id and v.observacoes like '[seed]%') as parcelas,
         (select count(*) from public.boletos    where consultora_id = v_id and observacoes like '[seed]%') as boletos
    into n_resultado;
  raise notice 'Seed ok: % clientes, % produtos, % vendas, % parcelas, % boletos',
    n_resultado.clientes, n_resultado.produtos, n_resultado.vendas, n_resultado.parcelas, n_resultado.boletos;
end
$seed$;
