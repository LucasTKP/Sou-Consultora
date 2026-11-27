-- Dados de VITRINE para os prints das lojas: negócio saudável (R$ 20 a 30 mil
-- por mês, abaixo de 1.000 linhas por consulta), poucas cobranças atrasadas, boletos em dia e lembretes de recompra.
-- Nomes de produtos e fornecedores são genéricos (sem marcas de terceiros).
--
-- Rode à mão (papel postgres), numa conta SEM outros dados de seed. Nenhum texto
-- de marcação aparece no app: tudo o que o script cria tem id começando em
-- '5eed0000-', e `limpar_vitrine.sql` apaga só isso.
--
-- As datas são relativas ao dia em que roda: tire os prints no mesmo dia.

do $vitrine$
declare
  v_id    uuid := '0f76794d-cebd-458b-9166-15f8f407d45f';
  v_hoje  date := (now() at time zone 'America/Sao_Paulo')::date;
  v_cod   int;
  v_cat   uuid;
  v_cats  uuid;
begin
  if not exists (select 1 from public.consultoras where id = v_id) then
    raise exception 'Consultora % não encontrada.', v_id;
  end if;
  if exists (select 1 from public.clientes where consultora_id = v_id and id::text like '5eed0000-%') then
    raise exception 'Vitrine já criada. Rode limpar_vitrine.sql antes.';
  end if;
  select id into v_cat  from public.categorias where consultora_id = v_id and tipo = 'produto' order by nome limit 1;
  select id into v_cats from public.categorias where consultora_id = v_id and tipo = 'servico' order by nome limit 1;
  if v_cat is null or v_cats is null then
    raise exception 'A conta precisa de categorias de produto e de serviço.';
  end if;

  perform setseed(0.7);
  create function pg_temp.novo_id() returns uuid language sql volatile as
    $f$ select ('5eed0000' || substr(gen_random_uuid()::text, 9))::uuid $f$;

  -- Fornecedores fictícios
  create temp table t_forn on commit drop as
  select pg_temp.novo_id() as id, x.n, x.nome, x.ramo, x.contato
    from (values (1,'Bella Essência','Perfumaria','Marina'), (2,'Flor de Lis Cosméticos','Cosméticos','Paulo'),
                 (3,'Aurora Beleza','Maquiagem','Renata'), (4,'Vita Pele','Cuidados com a pele','Carlos'),
                 (5,'Casa dos Aromas','Casa e presentes','Sônia')) x(n, nome, ramo, contato);
  insert into public.fornecedores (id, consultora_id, nome, ramo, contato, telefone)
  select id, v_id, nome, ramo, contato, '1190000010' || n from t_forn;

  -- Clientes
  create temp table t_cli on commit drop as
  select pg_temp.novo_id() as id, pg_temp.novo_id() as endereco_id, row_number() over () as n, nome
    from unnest(array[
      'Ana Beatriz Souza','Juliana Martins','Fernanda Lima','Camila Rocha','Patrícia Alves','Larissa Gomes',
      'Renata Carvalho','Aline Ferreira','Vanessa Ribeiro','Gabriela Nunes','Mariana Costa','Luciana Dias',
      'Priscila Moreira','Débora Andrade','Tatiane Lopes','Carla Mendes','Simone Barbosa','Helena Freitas',
      'Isabela Machado','Letícia Vieira','Raquel Soares','Viviane Marques','Adriana Pereira','Bruna Oliveira',
      'Cláudia Santos','Sandra Almeida','Mônica Fernandes','Eliane Rodrigues','Rosana Silva','Amanda Teixeira',
      'Bianca Cardoso','Daniela Moura','Elaine Castro','Flávia Pinto','Giovana Araújo','Ingrid Ramos',
      'Jaqueline Correia','Karina Melo','Lívia Duarte','Michele Farias','Natália Campos','Paula Rezende',
      'Rafaela Monteiro','Sabrina Cunha','Talita Barros','Úrsula Pires','Valéria Nogueira','Yasmin Borges',
      'Cristina Azevedo','Eduarda Tavares','Fabiana Sales','Heloísa Prado','Joana Siqueira','Lorena Batista',
      'Márcia Guimarães','Nicole Fonseca','Olívia Brandão','Pietra Amaral','Roberta Xavier','Silvana Leite',
      'Thaís Coelho','Vera Macedo','Alice Figueiredo','Bárbara Assis','Cecília Porto','Diana Queiroz',
      'Estela Vargas','Francine Luz','Glória Antunes','Iara Bittencourt','Júlia Sampaio','Kelly Peixoto',
      'Luana Rangel','Manuela Serra','Noemi Paiva','Paloma Viana','Regina Matos','Sofia Menezes',
      'Marina Lacerda','Carolina Brito','Denise Arruda']) as nome;

  insert into public.enderecos (id, consultora_id, cep, rua, numero, bairro, cidade, uf)
  select endereco_id, v_id, '13000000',
         (array['Rua das Flores','Rua das Acácias','Avenida Central','Rua Bela Vista'])[1 + n % 4],
         (20 + n * 7)::text, (array['Centro','Jardim América','Vila Nova','Cambuí'])[1 + n % 4], 'Campinas', 'SP'
    from t_cli;

  insert into public.clientes (id, consultora_id, endereco_id, nome, whatsapp, data_nascimento, observacoes)
  select id, v_id, endereco_id, nome, '119' || lpad(n::text, 8, '0'),
         case
           when n = 1 then (v_hoje - interval '31 years')::date
           when n = 2 then (v_hoje + 2 - interval '28 years')::date
           else date '1975-01-01' + ((n * 137) % 9000)::int
         end,
         case n % 6
           when 1 then 'Prefere fragrâncias florais. Melhor horário: à tarde.'
           when 3 then 'Pele sensível. Gosta de novidades em hidratantes.'
         end
    from t_cli;

  -- Produtos. Só os com durabilidade geram lembrete de recompra; por isso eles
  -- ficam fora das vendas sorteadas e entram apenas nas vendas montadas abaixo.
  create temp table t_prod on commit drop as
  select pg_temp.novo_id() as id, x.*
    from (values
      (1,1,'Perfume Floral 75 ml',139.90,null::int), (2,1,'Perfume Amadeirado 100 ml',159.90,null),
      (3,1,'Colônia Cítrica 150 ml',89.90,null), (4,1,'Perfume Doce Baunilha 50 ml',119.90,null),
      (5,2,'Hidratante Corporal Amêndoas 400 ml',59.90,null), (6,2,'Creme para as Mãos 75 g',29.90,null),
      (7,2,'Sabonete Líquido Lavanda 250 ml',34.90,null), (8,2,'Óleo Corporal Perfumado 200 ml',69.90,null),
      (9,3,'Batom Matte Rosé',39.90,null), (10,3,'Batom Cremoso Vermelho',37.90,null),
      (11,3,'Base Líquida Bege Claro',69.90,null), (12,3,'Máscara de Cílios Volume',49.90,null),
      (13,3,'Paleta de Sombras Nude',89.90,null), (14,3,'Pó Compacto Translúcido',54.90,null),
      (15,4,'Protetor Solar Facial FPS 50',74.90,null), (16,4,'Sérum Vitamina C 30 ml',109.90,null),
      (17,4,'Água Micelar 200 ml',44.90,null), (18,4,'Creme Antissinais Noturno',129.90,null),
      (19,5,'Kit Presente Floral',179.90,null), (20,5,'Difusor de Ambientes 250 ml',79.90,null),
      (21,5,'Vela Aromática Baunilha',49.90,null), (22,2,'Esfoliante Corporal 200 g',54.90,null),
      (23,2,'Shampoo Nutritivo 300 ml',39.90,null), (24,2,'Condicionador Nutritivo 300 ml',42.90,null),
      (25,2,'Hidratante Facial Diário 50 g',64.90,60), (26,1,'Desodorante Colônia Frescor 100 ml',79.90,45),
      (27,4,'Gel de Limpeza Facial 150 g',49.90,45), (28,2,'Máscara Capilar Reparadora 250 g',57.90,60)
    ) x(n, forn, nome, preco, dur);

  insert into public.produtos (id, consultora_id, fornecedor_id, categoria_id, nome, codigo,
                               preco_venda, preco_custo, durabilidade_dias)
  select p.id, v_id, f.id, v_cat, p.nome, (4100 + p.n)::text, p.preco, round(p.preco * 0.6, 2), p.dur
    from t_prod p join t_forn f on f.n = p.forn;

  create temp table t_serv on commit drop as
  select pg_temp.novo_id() as id, x.*
    from (values (1,'Design de Sobrancelhas',45.00,30), (2,'Maquiagem Social',130.00,60),
                 (3,'Limpeza de Pele',120.00,75), (4,'Manicure e Pedicure',65.00,90)) x(n, nome, preco, minutos);
  insert into public.servicos (id, consultora_id, categoria_id, nome, preco_cobrado, custo_materiais, duracao_minutos)
  select id, v_id, v_cats, nome, preco, round(preco * 0.15, 2), minutos from t_serv;

  -- Vendas sorteadas: crescimento suave ao longo de 12 meses.
  create temp table t_venda on commit drop as
  select pg_temp.novo_id() as id, (1 + floor(random() * 78))::int as cli, d.dia, d.np, 'sorteada'::text as tipo,
         0 as prod
    from (
      select case when m.atras = 0 then date_trunc('month', v_hoje)::date + floor(random() * extract(day from v_hoje))::int
                  else (date_trunc('month', v_hoje) - make_interval(months => m.atras))::date + floor(random() * 28)::int
             end as dia,
             (array[1,1,1,1,1,1,1,2])[1 + floor(random() * 8)::int] as np
        from (values (11,52),(10,54),(9,53),(8,55),(7,56),(6,57),(5,58),(4,59),(3,60),(2,62),(1,66),(0,64)) m(atras, qtd)
        cross join lateral generate_series(1, m.qtd) g
    ) d;

  -- Vendas montadas: lembretes de recompra, poucas atrasadas e vendas de hoje.
  insert into t_venda
  select pg_temp.novo_id(), x.cli, v_hoje - x.atras, x.np, x.tipo, x.prod
    from (values
      -- (cliente, dias atrás, parcelas, tipo, produto)
      (3, 58, 1, 'lembrete', 25), (4, 44, 1, 'lembrete', 26), (5, 43, 1, 'lembrete', 27),
      (6, 56, 1, 'lembrete', 28), (7, 47, 1, 'lembrete', 26),
      (79, 38, 2, 'atrasada', 1), (80, 35, 2, 'atrasada', 16), (81, 42, 2, 'atrasada', 13),
      (1, 0, 1, 'hoje', 19), (8, 0, 2, 'hoje', 2), (9, 0, 1, 'hoje', 11),
      (10, 30, 2, 'vence_hoje', 18)
    ) x(cli, atras, np, tipo, prod);

  create temp table t_item on commit drop as
  with cand as (
    select v.id as venda_id, (random() < 0.88) as eh_produto,
           1 + floor(random() * 24)::int as pn, 1 + floor(random() * 4)::int as sn,
           case when random() < 0.5 then 2 else 1 end as qtd,
           random() as r_desc
      from t_venda v
      cross join lateral generate_series(1, (array[2,3,3,4,4,5])[1 + floor(random() * 6)::int] + length(v.tipo) * 0) k
     where v.tipo = 'sorteada'
    union all
    select v.id, true, v.prod, 1, case when v.tipo = 'lembrete' then 1 else 2 end, 1
      from t_venda v where v.tipo <> 'sorteada'
  ), unicos as (
    select distinct on (venda_id, eh_produto, case when eh_produto then pn else sn end) *
      from cand order by venda_id, eh_produto, case when eh_produto then pn else sn end
  )
  select pg_temp.novo_id() as id, u.venda_id, p.id as produto_id, s.id as servico_id, u.qtd,
         coalesce(p.preco, s.preco) as preco, coalesce(round(p.preco * 0.6, 2), 0) as custo,
         case when u.r_desc < 0.15 then round(coalesce(p.preco, s.preco) * u.qtd * 0.05, 2) else 0 end as desconto
    from unicos u
    left join t_prod p on u.eh_produto and p.n = u.pn
    left join t_serv s on not u.eh_produto and s.n = u.sn;

  select ultimo_codigo_venda into v_cod from public.consultoras where id = v_id;

  insert into public.vendas (id, consultora_id, cliente_id, codigo, data_venda, subtotal, total_descontos, total)
  select v.id, v_id, c.id, v_cod + row_number() over (order by v.dia, v.id),
         case when v.dia = v_hoje then now() - random() * interval '1 hour'
              else (v.dia::timestamp + interval '9 hours' + random() * interval '9 hours') at time zone 'America/Sao_Paulo'
         end,
         x.bruto, x.desconto, x.bruto - x.desconto
    from t_venda v
    join t_cli c on c.n = v.cli
    join (select venda_id, sum(preco * qtd) as bruto, sum(desconto) as desconto from t_item group by 1) x
      on x.venda_id = v.id;

  update public.consultoras set ultimo_codigo_venda = v_cod + (select count(*) from t_venda) where id = v_id;

  -- Estoque: um lote por produto, com sobra confortável.
  create temp table t_lanc on commit drop as select pg_temp.novo_id() as id, id as fornecedor_id, n from t_forn;
  insert into public.lancamentos_estoque (id, consultora_id, fornecedor_id, data_compra)
  select id, v_id, fornecedor_id, v_hoje - 370 from t_lanc;

  create temp table t_lote on commit drop as
  select pg_temp.novo_id() as id, p.id as produto_id, p.n, p.forn, p.preco,
         coalesce((select sum(qtd) from t_item i where i.produto_id = p.id), 0)::int as saiu,
         case when p.n in (9, 16) then 2 else 6 + (p.n * 7) % 19 end as sobra
    from t_prod p;
  insert into public.lotes_estoque (id, consultora_id, lancamento_id, produto_id, numero_lote,
                                    quantidade, quantidade_disponivel, custo_unitario, validade)
  select l.id, v_id, la.id, l.produto_id, 1, l.saiu + l.sobra, l.sobra, round(l.preco * 0.6, 2), v_hoje + 240 + l.n * 9
    from t_lote l join t_lanc la on la.n = l.forn;

  insert into public.itens_venda (id, consultora_id, venda_id, produto_id, servico_id, quantidade,
                                  preco_unitario, custo_unitario, desconto, subtotal, baixar_estoque)
  select id, v_id, venda_id, produto_id, servico_id, qtd, preco, custo, desconto, preco * qtd - desconto,
         produto_id is not null
    from t_item;

  insert into public.saidas_estoque (consultora_id, item_venda_id, lote_id, quantidade)
  select v_id, i.id, l.id, i.qtd from t_item i join t_lote l on l.produto_id = i.produto_id;

  -- Parcelas: a 1ª na data da venda, as demais de 30 em 30 dias.
  create temp table t_parcela on commit drop as
  select pg_temp.novo_id() as id, v.id as venda_id, v.tipo, k as numero,
         case when k < v.np then round(ve.total / v.np, 2) else ve.total - round(ve.total / v.np, 2) * (v.np - 1) end as valor,
         v.dia + (k - 1) * 30 as vencimento
    from t_venda v join public.vendas ve on ve.id = v.id
    cross join lateral generate_series(1, v.np) k;
  insert into public.parcelas (id, consultora_id, venda_id, numero_parcela, valor, data_vencimento)
  select id, v_id, venda_id, numero, valor, vencimento from t_parcela;

  -- Tudo que já venceu está pago, menos a 2ª parcela das três vendas atrasadas.
  -- 'vence_hoje' fica com a 2ª parcela em aberto para hoje.
  insert into public.pagamentos_parcela (consultora_id, parcela_id, valor, forma_pagamento, data_pagamento)
  select v_id, id, valor, (array['pix','pix','pix','cartao','dinheiro'])[1 + floor(random() * 5)::int],
         case when vencimento >= v_hoje then now() - interval '5 minutes'
              else (vencimento::timestamp + interval '15 hours') at time zone 'America/Sao_Paulo' end
    from t_parcela
   where (vencimento < v_hoje and not (tipo = 'atrasada' and numero = 2))
      or (vencimento = v_hoje and tipo not in ('vence_hoje', 'atrasada'));

  -- Boletos: passado todo pago; um vence hoje, um amanhã e alguns adiante.
  insert into public.boletos (id, consultora_id, fornecedor_id, valor, data_vencimento, forma_pagamento, data_pagamento)
  select pg_temp.novo_id(), v_id, f.id, b.valor, b.vencimento,
         case when b.vencimento < v_hoje then 'pix' end,
         case when b.vencimento < v_hoje then b.vencimento - 1 end
    from (
      select 1 + (m * 4 + k) % 5 as forn, round((2200 + random() * 1600 + (11 - m) * 90)::numeric, 2) as valor,
             (date_trunc('month', v_hoje) - make_interval(months => m))::date + k * 6 as vencimento
        from generate_series(0, 11) m cross join generate_series(0, 3) k
       where (date_trunc('month', v_hoje) - make_interval(months => m))::date + k * 6 < v_hoje
      union all
      select * from (values (1, 1289.40, v_hoje), (3, 864.90, v_hoje + 1), (2, 1540.00, v_hoje + 9),
                            (4, 978.50, v_hoje + 16), (5, 1120.00, v_hoje + 28)) f(forn, valor, vencimento)
    ) b join t_forn f on f.n = b.forn;

  drop function pg_temp.novo_id();
  raise notice 'Vitrine ok: % clientes, % produtos, % vendas',
    (select count(*) from t_cli), (select count(*) from t_prod), (select count(*) from t_venda);
end
$vitrine$;
