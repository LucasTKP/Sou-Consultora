-- RLS — Sou Consultora
-- Cada consultora só lê e grava as próprias linhas. Ver .claude/rules/seguranca.md §1.
-- Toda tabela nova deve entrar aqui (o teste 01_rls_em_todas_tabelas.sql falha se faltar).

-- =====================================================================
-- consultoras: a dona é o próprio id. Sem policy de delete:
-- a remoção acontece só por public.apagar_minha_conta().
-- =====================================================================

alter table public.consultoras enable row level security;
alter table public.consultoras force row level security;

create policy consultoras_select on public.consultoras
  for select to authenticated
  using (id = (select auth.uid()));

create policy consultoras_insert on public.consultoras
  for insert to authenticated
  with check (id = (select auth.uid()));

create policy consultoras_update on public.consultoras
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- =====================================================================
-- Demais tabelas: 4 policies por consultora_id.
-- =====================================================================

do $$
declare
  v_tabela text;
begin
  foreach v_tabela in array array[
    'enderecos', 'clientes', 'fornecedores', 'categorias', 'produtos', 'servicos',
    'lancamentos_estoque', 'lotes_estoque', 'vendas', 'itens_venda', 'parcelas',
    'pagamentos_parcela', 'saidas_estoque', 'boletos'
  ]
  loop
    execute format('alter table public.%I enable row level security', v_tabela);
    execute format('alter table public.%I force row level security', v_tabela);

    execute format(
      'create policy %I on public.%I for select to authenticated
         using (consultora_id = (select auth.uid()))',
      v_tabela || '_select', v_tabela);

    execute format(
      'create policy %I on public.%I for insert to authenticated
         with check (consultora_id = (select auth.uid()))',
      v_tabela || '_insert', v_tabela);

    execute format(
      'create policy %I on public.%I for update to authenticated
         using (consultora_id = (select auth.uid()))
         with check (consultora_id = (select auth.uid()))',
      v_tabela || '_update', v_tabela);

    execute format(
      'create policy %I on public.%I for delete to authenticated
         using (consultora_id = (select auth.uid()))',
      v_tabela || '_delete', v_tabela);
  end loop;
end $$;
