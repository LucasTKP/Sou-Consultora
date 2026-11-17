-- Tabelas — Sou Consultora
-- Referência de produto: ../banco-de-dados.md
-- Regras de segurança: .claude/rules/seguranca.md
--
-- Padrões aplicados em todas as tabelas:
--   * consultora_id uuid not null default auth.uid() → o app nunca envia a dona.
--   * unique (consultora_id, id) → permite FKs compostas.
--   * FKs internas compostas (consultora_id, x_id) → impedem vínculo entre consultoras.
--   * Cadastros referenciados usam NO ACTION (padrão): recusa apagar em uso,
--     mas não quebra o cascade ao apagar a consultora (checagem no fim do comando).
--   * Filhos da venda usam ON DELETE CASCADE.

-- =====================================================================
-- Consultora
-- =====================================================================

create table public.consultoras (
  id                  uuid primary key default auth.uid()
                      references auth.users (id) on delete cascade,
  nome                text not null check (length(btrim(nome)) > 0),
  whatsapp            text not null check (length(btrim(whatsapp)) > 0),
  foto_url            text,
  chave_pix           text,
  tipo_chave_pix      text check (tipo_chave_pix in ('telefone', 'cpf', 'email', 'aleatoria')),
  ultimo_codigo_venda integer not null default 0 check (ultimo_codigo_venda >= 0),
  created_at          timestamptz not null default now()
);

-- =====================================================================
-- Clientes e endereços
-- =====================================================================

create table public.enderecos (
  id            uuid primary key default gen_random_uuid(),
  consultora_id uuid not null default auth.uid()
                references public.consultoras (id) on delete cascade,
  cep           text,
  rua           text,
  numero        text,
  complemento   text,
  bairro        text,
  cidade        text,
  uf            char(2) check (uf ~ '^[A-Z]{2}$'),
  referencia    text,
  created_at    timestamptz not null default now(),
  unique (consultora_id, id)
);

create table public.clientes (
  id              uuid primary key default gen_random_uuid(),
  consultora_id   uuid not null default auth.uid()
                  references public.consultoras (id) on delete cascade,
  endereco_id     uuid,
  nome            text not null check (length(btrim(nome)) > 0),
  whatsapp        text not null check (length(btrim(whatsapp)) > 0),
  data_nascimento date,
  observacoes     text,
  created_at      timestamptz not null default now(),
  unique (consultora_id, id),
  foreign key (consultora_id, endereco_id)
    references public.enderecos (consultora_id, id) on delete set null (endereco_id)
);

-- =====================================================================
-- Catálogo
-- =====================================================================

create table public.fornecedores (
  id            uuid primary key default gen_random_uuid(),
  consultora_id uuid not null default auth.uid()
                references public.consultoras (id) on delete cascade,
  nome          text not null check (length(btrim(nome)) > 0),
  ramo          text,
  contato       text,
  telefone      text,
  observacoes   text,
  ativo         boolean not null default true,
  created_at    timestamptz not null default now(),
  unique (consultora_id, id)
);

create table public.categorias (
  id            uuid primary key default gen_random_uuid(),
  consultora_id uuid not null default auth.uid()
                references public.consultoras (id) on delete cascade,
  nome          text not null check (length(btrim(nome)) > 0),
  tipo          text not null check (tipo in ('produto', 'servico')),
  is_padrao     boolean not null default false,
  created_at    timestamptz not null default now(),
  unique (consultora_id, id)
);

create unique index categorias_nome_unico
  on public.categorias (consultora_id, tipo, lower(nome));

create table public.produtos (
  id                uuid primary key default gen_random_uuid(),
  consultora_id     uuid not null default auth.uid()
                    references public.consultoras (id) on delete cascade,
  fornecedor_id     uuid not null,
  categoria_id      uuid not null,
  nome              text not null check (length(btrim(nome)) > 0),
  codigo            text,
  preco_venda       numeric(12, 2) not null check (preco_venda >= 0),
  preco_custo       numeric(12, 2) check (preco_custo >= 0),
  durabilidade_dias integer check (durabilidade_dias between 30 and 180),
  observacoes       text,
  foto_url          text,
  created_at        timestamptz not null default now(),
  unique (consultora_id, id),
  foreign key (consultora_id, fornecedor_id) references public.fornecedores (consultora_id, id),
  foreign key (consultora_id, categoria_id)  references public.categorias (consultora_id, id)
);

create table public.servicos (
  id               uuid primary key default gen_random_uuid(),
  consultora_id    uuid not null default auth.uid()
                   references public.consultoras (id) on delete cascade,
  categoria_id     uuid not null,
  nome             text not null check (length(btrim(nome)) > 0),
  preco_cobrado    numeric(12, 2) not null check (preco_cobrado >= 0),
  custo_materiais  numeric(12, 2) check (custo_materiais >= 0),
  duracao_minutos  integer check (duracao_minutos > 0),
  retorno_dias     integer check (retorno_dias > 0),
  observacoes      text,
  foto_url         text,
  created_at       timestamptz not null default now(),
  unique (consultora_id, id),
  foreign key (consultora_id, categoria_id) references public.categorias (consultora_id, id)
);

-- =====================================================================
-- Estoque
-- =====================================================================

create table public.lancamentos_estoque (
  id            uuid primary key default gen_random_uuid(),
  consultora_id uuid not null default auth.uid()
                references public.consultoras (id) on delete cascade,
  fornecedor_id uuid not null,
  data_compra   date not null,
  created_at    timestamptz not null default now(),
  unique (consultora_id, id),
  foreign key (consultora_id, fornecedor_id) references public.fornecedores (consultora_id, id)
);

create table public.lotes_estoque (
  id                    uuid primary key default gen_random_uuid(),
  consultora_id         uuid not null default auth.uid()
                        references public.consultoras (id) on delete cascade,
  lancamento_id         uuid not null,
  produto_id            uuid not null,
  numero_lote           integer not null check (numero_lote > 0),
  quantidade            integer not null check (quantidade > 0),
  quantidade_disponivel integer not null,
  custo_unitario        numeric(12, 2) not null check (custo_unitario >= 0),
  validade              date,
  created_at            timestamptz not null default now(),
  unique (consultora_id, id),
  unique (produto_id, numero_lote),
  check (quantidade_disponivel between 0 and quantidade),
  foreign key (consultora_id, lancamento_id) references public.lancamentos_estoque (consultora_id, id),
  foreign key (consultora_id, produto_id)    references public.produtos (consultora_id, id)
);

-- =====================================================================
-- Vendas
-- =====================================================================

create table public.vendas (
  id              uuid primary key default gen_random_uuid(),
  consultora_id   uuid not null default auth.uid()
                  references public.consultoras (id) on delete cascade,
  cliente_id      uuid not null,
  codigo          integer not null check (codigo > 0),
  data_venda      timestamptz not null default now(),
  subtotal        numeric(12, 2) not null check (subtotal >= 0),
  total_descontos numeric(12, 2) not null default 0 check (total_descontos >= 0),
  total           numeric(12, 2) not null check (total >= 0),
  observacoes     text,
  created_at      timestamptz not null default now(),
  unique (consultora_id, id),
  unique (consultora_id, codigo),
  check (total = subtotal - total_descontos),
  foreign key (consultora_id, cliente_id) references public.clientes (consultora_id, id)
);

create table public.itens_venda (
  id             uuid primary key default gen_random_uuid(),
  consultora_id  uuid not null default auth.uid()
                 references public.consultoras (id) on delete cascade,
  venda_id       uuid not null,
  produto_id     uuid,
  servico_id     uuid,
  quantidade     integer not null check (quantidade > 0),
  preco_unitario numeric(12, 2) not null check (preco_unitario >= 0),
  custo_unitario numeric(12, 2) check (custo_unitario >= 0),
  desconto       numeric(12, 2) not null default 0 check (desconto >= 0),
  subtotal       numeric(12, 2) not null check (subtotal >= 0),
  baixar_estoque boolean not null default true,
  unique (consultora_id, id),
  -- Exatamente um: produto OU serviço.
  check (num_nonnulls(produto_id, servico_id) = 1),
  -- Serviço nunca baixa estoque.
  check (servico_id is null or baixar_estoque = false),
  foreign key (consultora_id, venda_id)   references public.vendas (consultora_id, id) on delete cascade,
  foreign key (consultora_id, produto_id) references public.produtos (consultora_id, id),
  foreign key (consultora_id, servico_id) references public.servicos (consultora_id, id)
);

create table public.parcelas (
  id              uuid primary key default gen_random_uuid(),
  consultora_id   uuid not null default auth.uid()
                  references public.consultoras (id) on delete cascade,
  venda_id        uuid not null,
  numero_parcela  integer not null check (numero_parcela > 0),
  valor           numeric(12, 2) not null check (valor > 0),
  data_vencimento date not null,
  created_at      timestamptz not null default now(),
  unique (consultora_id, id),
  unique (venda_id, numero_parcela),
  foreign key (consultora_id, venda_id) references public.vendas (consultora_id, id) on delete cascade
);

create table public.pagamentos_parcela (
  id              uuid primary key default gen_random_uuid(),
  consultora_id   uuid not null default auth.uid()
                  references public.consultoras (id) on delete cascade,
  parcela_id      uuid not null,
  valor           numeric(12, 2) not null check (valor > 0),
  forma_pagamento text not null check (forma_pagamento in ('pix', 'cartao', 'dinheiro')),
  data_pagamento  timestamptz not null default now(),
  observacao      text,
  created_at      timestamptz not null default now(),
  unique (consultora_id, id),
  foreign key (consultora_id, parcela_id) references public.parcelas (consultora_id, id) on delete cascade
);

create table public.saidas_estoque (
  id            uuid primary key default gen_random_uuid(),
  consultora_id uuid not null default auth.uid()
                references public.consultoras (id) on delete cascade,
  item_venda_id uuid not null,
  lote_id       uuid not null,
  quantidade    integer not null check (quantidade > 0),
  created_at    timestamptz not null default now(),
  unique (consultora_id, id),
  foreign key (consultora_id, item_venda_id) references public.itens_venda (consultora_id, id) on delete cascade,
  foreign key (consultora_id, lote_id)       references public.lotes_estoque (consultora_id, id)
);

-- =====================================================================
-- A pagar
-- =====================================================================

create table public.boletos (
  id              uuid primary key default gen_random_uuid(),
  consultora_id   uuid not null default auth.uid()
                  references public.consultoras (id) on delete cascade,
  fornecedor_id   uuid not null,
  valor           numeric(12, 2) not null check (valor > 0),
  data_vencimento date not null,
  forma_pagamento text check (forma_pagamento in ('pix', 'boleto', 'transferencia')),
  observacoes     text,
  comprovante_url text,
  data_pagamento  date,
  created_at      timestamptz not null default now(),
  unique (consultora_id, id),
  foreign key (consultora_id, fornecedor_id) references public.fornecedores (consultora_id, id)
);

-- =====================================================================
-- Índices das FKs (buscas e remoções)
-- =====================================================================

create index clientes_endereco_idx           on public.clientes (endereco_id);
create index produtos_fornecedor_idx         on public.produtos (fornecedor_id);
create index produtos_categoria_idx          on public.produtos (categoria_id);
create index servicos_categoria_idx          on public.servicos (categoria_id);
create index lancamentos_fornecedor_idx      on public.lancamentos_estoque (fornecedor_id);
create index lotes_lancamento_idx            on public.lotes_estoque (lancamento_id);
create index lotes_produto_idx               on public.lotes_estoque (produto_id);
create index vendas_cliente_idx              on public.vendas (cliente_id);
create index vendas_data_idx                 on public.vendas (consultora_id, data_venda);
create index itens_venda_venda_idx           on public.itens_venda (venda_id);
create index itens_venda_produto_idx         on public.itens_venda (produto_id);
create index itens_venda_servico_idx         on public.itens_venda (servico_id);
create index parcelas_vencimento_idx         on public.parcelas (consultora_id, data_vencimento);
create index pagamentos_parcela_parcela_idx  on public.pagamentos_parcela (parcela_id);
create index pagamentos_parcela_data_idx     on public.pagamentos_parcela (consultora_id, data_pagamento);
create index saidas_item_idx                 on public.saidas_estoque (item_venda_id);
create index saidas_lote_idx                 on public.saidas_estoque (lote_id);
create index boletos_fornecedor_idx          on public.boletos (fornecedor_id);
create index boletos_vencimento_idx          on public.boletos (consultora_id, data_vencimento);
