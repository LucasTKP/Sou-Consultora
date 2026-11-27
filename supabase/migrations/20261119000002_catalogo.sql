-- Catálogo de produtos das marcas (importar no cadastro de produto).
--
-- EXCEÇÃO DECIDIDA PELO DONO (2026-11-19) às regras de .claude/rules/seguranca.md:
-- tabela global (sem consultora_id), lida por TODAS as consultoras logadas.
-- Continua fechada para anon. Só o dono grava (painel/CLI com service_role);
-- nenhuma policy de escrita = o app não consegue inserir, alterar nem apagar.
-- Quando a consultora importa um produto, o app COPIA os dados para o produto
-- dela (e a foto para a pasta dela): o catálogo nunca é referenciado por FK.
-- Fotos ficam no bucket privado `catalogo` (leitura só para authenticated,
-- exibição por URL assinada).

create table public.catalogo_produtos (
  id uuid primary key default gen_random_uuid(),
  marca text not null,
  codigo text not null,
  nome text not null,
  -- Nome da categoria padrão da consultora (ex.: 'Maquiagem'); null = sem sugestão.
  categoria text,
  -- Caminho no bucket `catalogo` (ex.: 'natura/174918.jpg').
  foto_caminho text,
  unique (marca, codigo)
);

create index catalogo_produtos_marca_nome on public.catalogo_produtos (marca, lower(nome));

alter table public.catalogo_produtos enable row level security;
alter table public.catalogo_produtos force row level security;

create policy catalogo_produtos_select on public.catalogo_produtos
  for select to authenticated
  using (true);

revoke all on public.catalogo_produtos from anon, authenticated, public;
grant select on public.catalogo_produtos to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('catalogo', 'catalogo', false, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public             = excluded.public,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Só leitura. Sem policy de insert/update/delete: o app não grava no bucket.
create policy catalogo_leitura on storage.objects
  for select to authenticated
  using (bucket_id = 'catalogo');
