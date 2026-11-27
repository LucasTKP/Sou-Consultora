-- Busca sem acento e sem diferenciar maiúsculas no catálogo (nome + código).
-- `busca` é mantida por trigger: qualquer carga futura (script, painel) já preenche sozinha.

create extension if not exists unaccent with schema extensions;

alter table public.catalogo_produtos add column busca text;

create function public.catalogo_produtos_preparar_busca()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  -- Dicionário qualificado: com search_path vazio, o unaccent de 1 argumento não o encontra.
  new.busca := lower(extensions.unaccent('extensions.unaccent'::regdictionary, new.nome || ' ' || new.codigo));
  return new;
end $$;

revoke execute on function public.catalogo_produtos_preparar_busca() from public, anon, authenticated;

create trigger catalogo_produtos_busca
  before insert or update of nome, codigo on public.catalogo_produtos
  for each row execute function public.catalogo_produtos_preparar_busca();

-- Preenche o que já existe (o "update of nome" dispara o trigger mesmo sem mudar o valor).
update public.catalogo_produtos set nome = nome;

alter table public.catalogo_produtos alter column busca set not null;
