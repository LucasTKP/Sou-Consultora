# Tasks

## 1. Ambiente Supabase local

- [x] 1.1 Rodar `supabase init` em `sou_consultora_app/` e conferir que `supabase/config.toml` existe e que `supabase/.temp` e `supabase/.branches` estão no `.gitignore`
- [x] 1.2 Rodar `supabase start` e verificar que o Postgres local responde (`supabase status` mostra a DB URL)
- [x] 1.3 Criar `supabase/tests/00_auxiliares.sql` com `testes.criar_usuario`, `testes.autenticar_como` e `testes.anonimo`; verificar com um teste pgTAP trivial passando em `supabase test db`

## 2. Base de privilégios

- [x] 2.1 Criar a migração `..._base.sql`: revoga tudo de `anon` no schema `public` e ajusta os `default privileges` de tabelas e funções; verificar com `supabase db reset` sem erro

## 3. Tabelas e integridade

- [x] 3.1 Criar a migração `..._tabelas.sql` com `consultoras` (FK para `auth.users` on delete cascade, `ultimo_codigo_venda`, check de `tipo_chave_pix`), `enderecos`, `clientes`, `fornecedores` e `categorias`, com `consultora_id not null default auth.uid()`, `unique (consultora_id, id)`, FKs compostas e índices; verificar com `supabase db reset`
- [x] 3.2 Acrescentar `produtos`, `servicos`, `lancamentos_estoque` e `lotes_estoque` (CHECKs de preço, durabilidade 30–180, `quantidade_disponivel between 0 and quantidade`, `unique (produto_id, numero_lote)`); verificar com `supabase db reset`
- [x] 3.3 Acrescentar `vendas`, `itens_venda`, `parcelas`, `pagamentos_parcela`, `saidas_estoque` e `boletos`:
  - CHECK produto XOR serviço;
  - CHECK serviço sem baixa de estoque;
  - formas de pagamento válidas;
  - `unique (consultora_id, codigo)` e `unique (venda_id, numero_parcela)`;
  - cascade nos filhos da venda e `NO ACTION` nos cadastros.

  Verificar com `supabase db reset`.
- [x] 3.4 Criar `supabase/tests/03_integridade.sql` cobrindo todos os cenários de `specs/modelo-de-dados` e verificar com `supabase test db` passando

## 4. RLS e isolamento

- [x] 4.1 Criar a migração `..._rls.sql`: `enable` + `force` RLS e as 4 policies `to authenticated` com `(select auth.uid())` em todas as tabelas (`consultoras` por `id`, sem policy de delete); verificar com `supabase db reset`
- [x] 4.2 Criar `supabase/tests/01_rls_em_todas_tabelas.sql` (varredura do catálogo) e verificar que passa; criar temporariamente uma tabela sem RLS e confirmar que o teste falha
- [x] 4.3 Criar `supabase/tests/02_isolamento.sql` com os cenários A × B × anon de `specs/isolamento-de-dados` (leitura, gravação, transferência de dona, FK cruzada, categorias) e verificar com `supabase test db` passando

## 5. Conta da consultora

- [x] 5.1 Criar a migração `..._conta.sql` com o trigger `after insert on consultoras` que copia as categorias padrão; verificar com `supabase db reset`
- [x] 5.2 Na mesma migração, criar `public.apagar_minha_conta()` (`security definer`, `search_path = ''`, erro se `auth.uid()` for nulo, `execute` só para `authenticated`); verificar com `supabase db reset`
- [x] 5.3 Criar `supabase/tests/04_conta.sql` com os cenários de `specs/conta-da-consultora` (registro único, categorias independentes, apagar remove tudo de A e preserva B, anon recusado) e verificar com `supabase test db` passando

## 6. Storage

- [x] 6.1 Criar a migração `..._storage.sql` com os buckets privados `fotos` e `comprovantes` (limites de tamanho e tipos) e as policies por pasta `<auth.uid()>/`; verificar com `supabase db reset`
- [x] 6.2 Criar `supabase/tests/05_storage.sql` com acesso à própria pasta, à pasta de outra consultora e anônimo, e verificar com `supabase test db` passando

## 7. Verificação final e documentação

- [x] 7.1 Rodar `supabase db reset && supabase test db` do zero e verificar que todos os testes passam
- [x] 7.2 Revisar cada migração contra o checklist de `.claude/rules/seguranca.md` e registrar o resultado no resumo da change
- [x] 7.3 Atualizar `../banco-de-dados.md` com a lista final de categorias padrão e a observação de que as migrações são a fonte da verdade técnica; verificar que os dois documentos não se contradizem

## Workflow follow-up

- Aplicar no Supabase remoto (`supabase link`, `supabase db diff --linked`, `supabase db push`) **somente após a confirmação do dono do projeto**.
- Arquivar a change com `/opsx:archive` depois de aplicada e revisada.

## Resultado da revisão (7.2) — checklist de `.claude/rules/seguranca.md`

| Item | Situação | Comprovado por |
|---|---|---|
| RLS habilitado e forçado | ✅ 15/15 tabelas | `01_rls_em_todas_tabelas.sql` |
| 4 policies `authenticated` com `auth.uid()` | ✅ (`consultoras` sem delete, por design) | `01_rls_em_todas_tabelas.sql` |
| `consultora_id NOT NULL DEFAULT auth.uid()` | ✅ 14/14 tabelas | `01_rls_em_todas_tabelas.sql`, `02_isolamento.sql` |
| FKs compostas com `consultora_id` | ✅ todas as FKs internas | `02_isolamento.sql` (venda/lote cruzados → 23503) |
| Views `security_invoker` | ✅ (nenhuma view ainda; varredura ativa) | `01_rls_em_todas_tabelas.sql` |
| RPC sem `consultora_id`, execute revogado de `anon` | ✅ `apagar_minha_conta()` | `01`, `02`, `04` |
| Storage privado por pasta | ✅ `fotos`, `comprovantes` | `05_storage.sql` |
| Testes A × B × anon | ✅ 94 testes passando após `db reset` | `supabase test db` |
| Varredura falha com tabela sem RLS | ✅ verificado injetando `tabela_esquecida` (falhou em 3 checagens) | execução manual na tarefa 4.2 |
