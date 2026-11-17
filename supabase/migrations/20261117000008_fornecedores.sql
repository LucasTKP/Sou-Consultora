-- Fornecedores — Sou Consultora (change `fornecedores`)
-- 1. Formatos: telefone só com dígitos (DDD + 8 ou 9) e nome único por consultora.
-- 2. View `resumo_fornecedores`: números dos boletos por fornecedor (security_invoker → herda o RLS).
-- O índice boletos (consultora_id, data_vencimento) já existe e atende "vence hoje" e "atrasados".

-- =====================================================================
-- 1. Formatos
-- =====================================================================

-- Telefones gravados antes do formato: fica só com os dígitos; o que não
-- for um telefone válido vira nulo (a migração não pode falhar por isso).
update public.fornecedores
   set telefone = case
         when regexp_replace(telefone, '\D', '', 'g') ~ '^[0-9]{10,11}$'
           then regexp_replace(telefone, '\D', '', 'g')
       end
 where telefone is not null
   and telefone !~ '^[0-9]{10,11}$';

alter table public.fornecedores
  add constraint fornecedores_telefone_digitos check (telefone is null or telefone ~ '^[0-9]{10,11}$');

create unique index fornecedores_nome_unico
  on public.fornecedores (consultora_id, lower(btrim(nome)));

-- =====================================================================
-- 2. Resumo por fornecedor
-- =====================================================================
-- "Hoje" é o dia em São Paulo, o mesmo que a consultora vê no aparelho.
-- Em aberto = sem data de pagamento (inclui os atrasados).

create view public.resumo_fornecedores
with (security_invoker = true) as
with
  hoje as (
    select (now() at time zone 'America/Sao_Paulo')::date as dia
  ),
  numeros as (
    select b.fornecedor_id,
           count(*)     filter (where b.data_pagamento is null)                        as qtd_em_aberto,
           sum(b.valor) filter (where b.data_pagamento is null)                        as valor_em_aberto,
           count(*)     filter (where b.data_pagamento is null and b.data_vencimento < h.dia) as qtd_atrasados,
           sum(b.valor) filter (where b.data_pagamento is null and b.data_vencimento < h.dia) as valor_atrasado,
           count(*)     filter (where b.data_pagamento is null and b.data_vencimento = h.dia) as qtd_vence_hoje,
           count(*)     filter (where b.data_pagamento is not null)                    as qtd_pagos,
           sum(b.valor) filter (where b.data_pagamento is not null)                    as valor_pagos
      from public.boletos b
     cross join hoje h
     group by b.fornecedor_id
  )
select f.id,
       f.nome,
       f.ramo,
       f.contato,
       f.telefone,
       f.observacoes,
       f.ativo,
       f.created_at,
       coalesce(n.qtd_em_aberto, 0)::integer           as qtd_em_aberto,
       coalesce(n.valor_em_aberto, 0)::numeric(12, 2)  as valor_em_aberto,
       coalesce(n.qtd_atrasados, 0)::integer           as qtd_atrasados,
       coalesce(n.valor_atrasado, 0)::numeric(12, 2)   as valor_atrasado,
       coalesce(n.qtd_vence_hoje, 0)::integer          as qtd_vence_hoje,
       coalesce(n.qtd_pagos, 0)::integer               as qtd_pagos,
       coalesce(n.valor_pagos, 0)::numeric(12, 2)      as valor_pagos
  from public.fornecedores f
  left join numeros n on n.fornecedor_id = f.id;

revoke all on public.resumo_fornecedores from anon, public;
grant select on public.resumo_fornecedores to authenticated;
