-- Base de privilégios — Sou Consultora
-- O papel anon (usuário sem sessão) não acessa nada no schema public.
-- Ver .claude/rules/seguranca.md §1 e §4.

revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;
revoke all on all functions in schema public from anon, public;

-- Objetos criados daqui em diante também nascem sem acesso para anon.
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on sequences from anon;
alter default privileges in schema public revoke all on functions from anon, public;
