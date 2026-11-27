-- Produtos — Sou Consultora (change `produtos`)
-- 1. Regras de gravação: categoria do tipo produto e código sem espaços nas pontas (vazio → nulo).
-- 2. View `resumo_produtos`: marca, categoria e estoque por produto (security_invoker → herda o RLS).
-- O índice lotes_estoque (produto_id) já existe e atende a soma dos lotes.

-- =====================================================================
-- 1. Regras de gravação
-- =====================================================================

-- Códigos gravados antes da regra: sem espaços nas pontas; vazio vira nulo.
update public.produtos
   set codigo = nullif(btrim(codigo), '')
 where codigo is distinct from nullif(btrim(codigo), '');

-- Roda com os privilégios de quem grava: a categoria de outra consultora
-- nem é encontrada (RLS) e a FK composta recusa do mesmo jeito.
create function public.preparar_produto()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.codigo := nullif(btrim(new.codigo), '');

  if not exists (
    select 1 from public.categorias c
     where c.consultora_id = new.consultora_id
       and c.id = new.categoria_id
       and c.tipo = 'produto'
  ) then
    raise exception 'A categoria do produto precisa ser do tipo produto.'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

revoke execute on function public.preparar_produto() from public, anon, authenticated;

create trigger produtos_preparar
  before insert or update of codigo, categoria_id, consultora_id on public.produtos
  for each row execute function public.preparar_produto();

-- =====================================================================
-- 2. Resumo por produto
-- =====================================================================
-- Estoque = soma do disponível nos lotes; validade atual = menor validade
-- entre os lotes que ainda têm unidades. Nada disso é gravado no produto.

create view public.resumo_produtos
with (security_invoker = true) as
with
  estoque as (
    select l.produto_id,
           sum(l.quantidade_disponivel)                                   as qtd_disponivel,
           min(l.validade) filter (where l.quantidade_disponivel > 0)     as validade_atual
      from public.lotes_estoque l
     group by l.produto_id
  )
select p.id,
       p.fornecedor_id,
       p.categoria_id,
       p.nome,
       p.codigo,
       p.preco_venda,
       p.preco_custo,
       p.durabilidade_dias,
       p.observacoes,
       p.foto_url,
       p.created_at,
       f.nome                              as fornecedor_nome,
       f.ativo                             as fornecedor_ativo,
       c.nome                              as categoria_nome,
       coalesce(e.qtd_disponivel, 0)::integer as qtd_disponivel,
       e.validade_atual
  from public.produtos p
  join public.fornecedores f on f.consultora_id = p.consultora_id and f.id = p.fornecedor_id
  join public.categorias c   on c.consultora_id = p.consultora_id and c.id = p.categoria_id
  left join estoque e on e.produto_id = p.id;

revoke all on public.resumo_produtos from anon, public;
grant select on public.resumo_produtos to authenticated;
