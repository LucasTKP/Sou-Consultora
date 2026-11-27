# Design

## Context

- O repositório não tem pasta `supabase/`. O app já usa um projeto Supabase remoto (login Google/Apple), mas sem schema versionado.
- Supabase CLI 2.54 e Docker estão disponíveis na máquina, o que permite banco local e testes pgTAP (`supabase test db`).
- Regras obrigatórias: `.claude/rules/seguranca.md`. Modelo de referência: `../banco-de-dados.md`.
- Motivação e escopo: ver `proposal.md`. Comportamento exigido: ver `specs/`.

## Goals / Non-Goals

**Goals:**
- Schema completo e versionado, reproduzível do zero com `supabase db reset`.
- Isolamento garantido pelo banco, sem depender do app, e comprovado por testes que falham sozinhos se uma tabela nova vier sem as regras.

**Non-Goals:**
- RPCs de negócio e views de indicadores (fases 3 a 7).
- Código Flutter (DTOs, services). Nenhum arquivo em `lib/` muda.
- Aplicar no projeto remoto de forma automática.

## Decisions

### 1. Migrações pelo Supabase CLI, em arquivos por assunto
Os arquivos ficam em `supabase/migrations/`:

| Migração | Conteúdo |
|---|---|
| `..._base.sql` | revogações do `anon`, `alter default privileges` |
| `..._tabelas.sql` | 15 tabelas, CHECKs, uniques, FKs, índices |
| `..._rls.sql` | `enable` + `force` RLS e as 4 policies de cada tabela |
| `..._conta.sql` | trigger de categorias padrão e `apagar_minha_conta()` |
| `..._storage.sql` | buckets e policies de `storage.objects` |

- **Por quê:** é o fluxo nativo do Supabase, com diff, `db reset` e `db push`, e cada arquivo é revisável isoladamente.
- **Alternativa descartada:** criar o schema pelo painel web, que não é versionado nem testável.

### 2. Dona da linha: `consultora_id uuid not null default auth.uid()`
- O app nunca envia o campo e a policy `with check` confere.
- Toda tabela referencia `consultoras(id) on delete cascade`.
- `consultoras.id` referencia `auth.users(id) on delete cascade`, de modo que apagar o login apaga tudo.

### 3. FKs compostas para impedir vínculo entre consultoras
- Toda tabela referenciável ganha `unique (consultora_id, id)`.
- Toda FK interna vira `foreign key (consultora_id, x_id) references x (consultora_id, id)`.
- FKs opcionais (`produto_id`/`servico_id` em itens, `endereco_id` em clientes) usam o comportamento padrão `MATCH SIMPLE`: com a coluna nula, a FK não é checada, que é o desejado.
- `clientes.endereco_id` usa `on delete set null (endereco_id)` (Postgres 15+). Isso anula só a coluna do endereço, e não o `consultora_id`.
- **Alternativa descartada:** validar em trigger. Seria mais código e mais fácil de esquecer em tabela nova.

### 4. Ações de remoção: `NO ACTION` em vez de `RESTRICT`
- Os cadastros referenciados (cliente, produto, serviço, fornecedor, categoria, lote) usam o padrão `NO ACTION`. Ele recusa apagar quando há uso, como pede a spec.
- **Por quê:** ao apagar a consultora, o cascade remove produtos e itens de venda **no mesmo comando**. `RESTRICT` checa na hora e quebraria esse cascade. `NO ACTION` só checa no fim do comando, quando os dois já foram removidos.
- Os filhos da venda (`itens_venda`, `parcelas`, `pagamentos_parcela`, `saidas_estoque`) usam `on delete cascade`.

### 5. Domínios como `text` + `CHECK`, não `enum` do Postgres
- `forma_pagamento`, `tipo_chave_pix` e `categorias.tipo` são `text` com `check (x in (...))`.
- **Por quê:** acrescentar um valor é uma migração simples; com `enum`, alterar ou remover valores é trabalhoso.

### 6. Valores monetários `numeric(12,2)`
Valores monetários usam `numeric(12,2)` com `check (>= 0)`. Quantidades usam `integer` com `check (> 0)`, exceto `quantidade_disponivel`, que usa `between 0 and quantidade`.

### 7. Policies
- O padrão está em `seguranca.md`: `to authenticated`, `(select auth.uid())`, que o Postgres avalia uma única vez por consulta.
- Há índice em `consultora_id` em toda tabela.
- `consultoras` não tem policy de delete: a remoção acontece só via `apagar_minha_conta()`.

### 8. Bloqueio do `anon`
```sql
revoke all on all tables in schema public from anon;
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on functions from anon, public;
```
- **Por quê:** o Supabase concede privilégios ao `anon` por padrão em toda tabela nova. O RLS já bloquearia, mas a revogação é uma segunda barreira.

### 9. Categorias padrão por trigger `after insert on consultoras`
- A função insere as categorias a partir de uma lista fixa dentro dela, com `consultora_id = new.id` e `is_padrao = true`.
  - Produto: Perfumaria, Maquiagem, Cuidados com a pele, Cabelos, Corpo e banho, Infantil, Masculino, Presentes.
  - Serviço: Unhas, Maquiagem, Sobrancelha, Tratamento facial, Depilação.
- Roda como `SECURITY INVOKER`. O insert passa na policy porque `new.id = auth.uid()`.
- **Alternativa descartada:** uma tabela de modelos legível por todos, o que violaria "nenhum dado compartilhado".

### 10. `apagar_minha_conta()`: única função `SECURITY DEFINER`
- **Justificativa:** o papel `authenticated` não pode apagar de `auth.users`.
- A função é `security definer` com `set search_path = ''` e faz `delete from auth.users where id = auth.uid()`. Se `auth.uid()` for nulo, ela gera um erro.
- `execute` é revogado de `anon` e `public` e concedido a `authenticated`.
- O cascade das decisões 2 e 4 remove todos os dados.
- O Supabase bloqueia apagar `storage.objects` por SQL. Por isso, numa fase futura, o app apaga os arquivos da pasta `<uid>/` pela API de Storage **antes** de chamar a função.

### 11. Storage
- O bucket `fotos` (perfil, produto, serviço) aceita jpeg/png/webp, até 5 MB.
- O bucket `comprovantes` aceita jpeg/png/pdf, até 10 MB.
- Os dois são `public = false`.
- As policies de select/insert/update/delete em `storage.objects` exigem `bucket_id in (...)` e `(storage.foldername(name))[1] = (select auth.uid())::text`.

### 12. Testes pgTAP em `supabase/tests/`
- `00_auxiliares.sql`: funções de teste `testes.criar_usuario(email)`, `testes.autenticar_como(uid)` (faz `set local role authenticated` e preenche `request.jwt.claims`) e `testes.anonimo()`.
- `01_rls_em_todas_tabelas.sql`: varre `pg_class` no schema `public` e falha se alguma tabela não tiver `relrowsecurity` e `relforcerowsecurity`, não tiver as 4 policies ou tiver policy para `anon`/`public`. É isso que pega uma tabela nova esquecida.
- `02_isolamento.sql`: cenários A × B × anon de leitura, gravação, transferência de dona e FK cruzada, por tabela.
- `03_integridade.sql`: CHECKs, uniques, cascade da venda e bloqueio de remoção de cadastros em uso.
- `04_conta.sql`: categorias copiadas, apagar a conta remove tudo de A e preserva B.
- `05_storage.sql`: acesso por pasta, cruzado e anônimo.
- Cada teste roda em transação com `rollback`.

## Risks / Trade-offs

- **[Remoção de arquivos fora da transação de apagar a conta]** Se o app falhar depois de apagar os arquivos e antes da RPC, a conta fica sem arquivos. No caso inverso, sobram arquivos órfãos, que continuam inacessíveis pelas policies. → O app apaga os arquivos primeiro. Uma limpeza periódica de órfãos pode vir depois.
- **[FKs compostas exigem `consultora_id` em todo insert com referência]** → O valor vem do default `auth.uid()`, então o app não precisa enviar nada.
- **[Banco remoto pode já ter tabelas criadas pelo painel]** → Antes do `db push`, rodar `supabase db diff --linked` e conferir com o dono do projeto.
- **[`FORCE RLS` também se aplica ao dono da tabela]** → As migrações e o `seed` rodam como `postgres`/superusuário, que tem `bypassrls`. Funções `SECURITY DEFINER` futuras precisam filtrar por `auth.uid()` explicitamente, como já exige `seguranca.md`.
- **[Versão do CLI]** O CLI 2.54 está desatualizado (existe a 3.x). → Funciona para este escopo. A atualização fica a critério do dono do projeto.

## Migration Plan

1. `supabase init` e `supabase start` (local).
2. `supabase db reset` aplica as migrações. `supabase test db` precisa passar 100%.
3. **Manual, com confirmação do dono do projeto:**
   - `supabase link --project-ref <ref>`
   - `supabase db diff --linked` para conferir se o banco remoto está vazio
   - `supabase db push`
4. **Rollback:** enquanto não houver dados reais, `supabase db reset --linked` ou uma migração de `drop`. Depois disso, só migrações corretivas.
