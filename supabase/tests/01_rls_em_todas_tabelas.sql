-- Varredura do catálogo: falha se qualquer tabela/função/view do schema public
-- não seguir .claude/rules/seguranca.md. Pega tabelas novas esquecidas.
begin;
select plan(8);

select is(
  (select array_agg(c.relname::text order by c.relname)
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind in ('r', 'p')
      and not (c.relrowsecurity and c.relforcerowsecurity)),
  null,
  'todas as tabelas têm RLS habilitado e forçado'
);

select is(
  (with tabelas as (
     select c.relname::text as tabela
       from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relkind in ('r', 'p')
   ), exigidas as (
     select t.tabela, x.cmd
       from tabelas t cross join unnest(array['SELECT', 'INSERT', 'UPDATE', 'DELETE']) as x (cmd)
      where not (t.tabela = 'consultoras' and x.cmd = 'DELETE')
   )
   select array_agg(e.tabela || ':' || e.cmd order by e.tabela, e.cmd)
     from exigidas e
    where not exists (
      select 1 from pg_policies p
       where p.schemaname = 'public' and p.tablename = e.tabela
         and p.cmd = e.cmd and 'authenticated' = any (p.roles))),
  null,
  'todas as tabelas têm as policies de select/insert/update/delete para authenticated'
);

select is(
  (select array_agg(p.tablename || '.' || p.policyname order by 1)
     from pg_policies p
    where p.schemaname = 'public' and p.roles && array['anon', 'public']::name[]),
  null,
  'nenhuma policy para anon ou public'
);

select is(
  (select array_agg(p.tablename || '.' || p.policyname order by 1)
     from pg_policies p
    where p.schemaname = 'public'
      and coalesce(p.qual, '') || coalesce(p.with_check, '') not like '%auth.uid()%'),
  null,
  'toda policy compara com auth.uid()'
);

select is(
  (select array_agg(distinct g.table_name::text)
     from information_schema.role_table_grants g
    where g.grantee = 'anon' and g.table_schema = 'public'),
  null,
  'anon não tem privilégio em nenhuma tabela'
);

select is(
  (select array_agg(c.relname::text order by c.relname)
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind in ('r', 'p') and c.relname <> 'consultoras'
      and not exists (
        select 1 from information_schema.columns col
         where col.table_schema = 'public' and col.table_name = c.relname
           and col.column_name = 'consultora_id' and col.is_nullable = 'NO'
           and col.column_default like '%auth.uid()%')),
  null,
  'toda tabela tem consultora_id not null default auth.uid()'
);

select is(
  (select array_agg(p.proname::text order by p.proname)
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and has_function_privilege('anon', p.oid, 'execute')),
  null,
  'anon não executa nenhuma função do schema public'
);

select is(
  (select array_agg(c.relname::text order by c.relname)
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind in ('v', 'm')
      and not coalesce('security_invoker=true' = any (c.reloptions), false)),
  null,
  'toda view usa security_invoker'
);

select * from finish();
rollback;
