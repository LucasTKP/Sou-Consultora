-- Serviços — Sou Consultora (change `servicos`)
-- 1. Categoria do serviço precisa ser do tipo serviço.
-- 2. View `resumo_servicos`: serviço + nome da categoria (security_invoker → herda o RLS).

-- Roda com os privilégios de quem grava: categoria de outra consultora nem é
-- encontrada (RLS) e a FK composta recusa do mesmo jeito.
create function public.preparar_servico()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.categorias c
     where c.consultora_id = new.consultora_id
       and c.id = new.categoria_id
       and c.tipo = 'servico'
  ) then
    raise exception 'A categoria do serviço precisa ser do tipo serviço.'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

revoke execute on function public.preparar_servico() from public, anon, authenticated;

create trigger servicos_preparar
  before insert or update of categoria_id, consultora_id on public.servicos
  for each row execute function public.preparar_servico();

create view public.resumo_servicos
with (security_invoker = true) as
select s.id,
       s.categoria_id,
       s.nome,
       s.preco_cobrado,
       s.custo_materiais,
       s.duracao_minutos,
       s.observacoes,
       s.foto_url,
       s.created_at,
       c.nome as categoria_nome
  from public.servicos s
  join public.categorias c on c.consultora_id = s.consultora_id and c.id = s.categoria_id;

revoke all on public.resumo_servicos from anon, public;
grant select on public.resumo_servicos to authenticated;
