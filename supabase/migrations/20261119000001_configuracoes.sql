-- Configurações do app (chave/valor): por enquanto, só a versão mínima de cada plataforma.
--
-- EXCEÇÃO DECIDIDA PELO DONO (2026-11-19) às regras de .claude/rules/seguranca.md:
-- esta é a única tabela global (sem consultora_id) e a única que o papel anon lê.
-- Motivo: o app precisa saber a versão mínima ANTES do login para bloquear versões antigas.
-- Não guarda dado de consultora nem segredo; nunca coloque nada sensível aqui.
-- Ninguém grava pelo app: INSERT/UPDATE/DELETE só pelo painel do Supabase (service_role/postgres).

create table public.configuracoes (
  chave text primary key,
  valor text not null
);

alter table public.configuracoes enable row level security;
alter table public.configuracoes force row level security;

-- Só leitura, e só desta tabela. Sem policy de escrita = ninguém grava pelo app.
create policy configuracoes_select on public.configuracoes
  for select to anon, authenticated
  using (true);

revoke all on public.configuracoes from anon, authenticated, public;
grant select on public.configuracoes to anon, authenticated;

insert into public.configuracoes (chave, valor) values
  ('versao_minima_android', '1.0.0'),
  ('versao_minima_ios', '1.0.0');
