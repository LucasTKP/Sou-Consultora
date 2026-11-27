# Segurança — Sou Consultora (obrigatória)

Princípio: **cada consultora só enxerga e altera os próprios dados.** Nenhum outro usuário, nem usuário anônimo, lê ou grava linha alguma que não seja dele. Nenhuma regra abaixo pode ser relaxada sem decisão explícita do dono do projeto.

## 1. RLS em todas as tabelas

- **Toda** tabela do schema `public` tem `ENABLE ROW LEVEL SECURITY` **e** `FORCE ROW LEVEL SECURITY`. Tabela sem RLS = migração rejeitada.
- Toda tabela tem `consultora_id uuid NOT NULL DEFAULT auth.uid()` (exceto `consultoras`, onde `id = auth.uid()`).
- Quatro policies separadas por tabela, só para o papel `authenticated`:

```sql
create policy "<tabela>_select" on <tabela> for select to authenticated
  using (consultora_id = (select auth.uid()));
create policy "<tabela>_insert" on <tabela> for insert to authenticated
  with check (consultora_id = (select auth.uid()));
create policy "<tabela>_update" on <tabela> for update to authenticated
  using (consultora_id = (select auth.uid()))
  with check (consultora_id = (select auth.uid()));
create policy "<tabela>_delete" on <tabela> for delete to authenticated
  using (consultora_id = (select auth.uid()));
```

- `consultoras`: mesmas policies com `id = (select auth.uid())`. Sem policy de insert pelo app se o registro for criado por trigger no cadastro.
- **Proibido**: policy com `using (true)`, policy para `anon`, policy de select "pública", e linhas compartilhadas entre consultoras.
- `revoke all on all tables in schema public from anon;` — o papel anônimo não acessa nada.

## 2. Sem dados compartilhados

- Não existe linha "do sistema" visível para todas. Categorias padrão são **copiadas** para a consultora no momento do cadastro (trigger), ficando com o `consultora_id` dela. `categorias.consultora_id` é `NOT NULL`.

## 3. Referências entre tabelas não podem cruzar consultoras

RLS não impede que uma venda aponte para o `cliente_id` de outra consultora. Por isso:

- Toda tabela referenciada tem `unique (consultora_id, id)`.
- Toda FK é **composta**: `foreign key (consultora_id, cliente_id) references clientes (consultora_id, id)`. Vale para todas as FKs entre tabelas da consultora.

## 4. Funções no banco (RPC)

- Padrão `SECURITY INVOKER` (respeita RLS).
- `SECURITY DEFINER` só com justificativa escrita na migração, `set search_path = ''`, nomes totalmente qualificados e filtro explícito por `auth.uid()` em toda query.
- **Nunca** receber `consultora_id` como parâmetro: sempre derivar de `auth.uid()`.
- Toda RPC valida que os IDs recebidos (cliente, produto, lote, parcela) pertencem à consultora antes de gravar.
- `revoke execute on function ... from anon, public;` e `grant execute ... to authenticated;`.

## 5. Views

- Toda view com `with (security_invoker = true)` para herdar o RLS das tabelas.

## 6. Storage (fotos e comprovantes)

- Buckets **privados**. Nada de bucket público.
- Caminho sempre começa com o id do usuário: `<auth.uid()>/...`.
- Policies em `storage.objects` exigindo `(storage.foldername(name))[1] = (select auth.uid())::text` para select, insert, update e delete.
- Exibição por **URL assinada** com expiração curta.

## 7. Chaves e segredos

- O app só conhece `SUPABASE_URL` e a chave **anon/publishable**. A chave `service_role` **nunca** entra no app, no `.env` do app nem no git.
- `.env` sempre no `.gitignore`. Valores via `envied` (ofuscados).

## 8. App (Flutter)

- O app **não envia** `consultora_id` nas gravações; o banco preenche com `auth.uid()` (default) e a policy confere.
- `core/api` não loga tokens, chave Pix, telefone nem dados de clientes. Em release, logs desligados.
- Sessão expirada ou erro 401/403 → `FalhaApp` de autenticação e volta ao login.
- **Apagar conta** remove o usuário do Auth e **todos** os dados dele (cascade a partir de `consultoras`) e os arquivos do Storage.

## 9. Teste obrigatório por migração

Cada migração que cria ou altera tabela, view, função ou bucket inclui teste SQL (pgTAP ou script) que prova:

1. Usuária A não lê, não altera e não apaga dados da usuária B.
2. Usuária A não consegue inserir linha com `consultora_id` de B.
3. Usuária A não consegue referenciar registro de B (FK composta).
4. Usuário `anon` não lê nada.

## Checklist de revisão (toda migração)

- [ ] RLS habilitado e forçado
- [ ] 4 policies `authenticated` com `auth.uid()`
- [ ] `consultora_id NOT NULL DEFAULT auth.uid()`
- [ ] FKs compostas com `consultora_id`
- [ ] Views `security_invoker`
- [ ] RPC sem `consultora_id` como parâmetro, execute revogado de `anon`
- [ ] Testes de isolamento A × B × anon passando
