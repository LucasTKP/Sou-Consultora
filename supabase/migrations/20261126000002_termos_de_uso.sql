-- Aceite dos Termos de Uso e da Política de Privacidade — Sou Consultora
--
-- `termos_versao` é a data do texto aceito; `termos_aceitos_em` é preenchida
-- SEMPRE pelo banco, para o app não escolher a data. Um aceite gravado não pode
-- ser apagado nem ter a data trocada. Colunas anuláveis: quem se cadastrou antes
-- (e a versão publicada do app) continua funcionando.
-- RLS: valem as policies de `consultoras` (id = auth.uid()).

alter table public.consultoras
  add column termos_versao     text check (termos_versao ~ '^\d{4}-\d{2}-\d{2}$'),
  add column termos_aceitos_em timestamptz;

create function public.registrar_aceite_termos()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE'
     and (new.termos_versao is null
          or new.termos_versao is not distinct from old.termos_versao) then
    new.termos_versao := old.termos_versao;
    new.termos_aceitos_em := old.termos_aceitos_em;
    return new;
  end if;

  new.termos_aceitos_em := case when new.termos_versao is not null then now() end;
  return new;
end;
$$;

revoke execute on function public.registrar_aceite_termos() from public, anon, authenticated;

create trigger consultoras_aceite_termos
  before insert or update on public.consultoras
  for each row execute function public.registrar_aceite_termos();
