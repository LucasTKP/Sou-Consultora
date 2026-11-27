-- A pagar — Sou Consultora
-- 1. Trigger em `boletos`: observação sem espaços nas pontas (vazia vira nulo) e
--    data de pagamento nunca no futuro (dia de São Paulo).
-- 2. View `resumo_boletos` (security_invoker): boleto + nome da marca.
-- A tabela `boletos`, o RLS (4 policies) e o bucket `comprovantes` já existem.
-- Gravar, pagar, desfazer e excluir são insert/update/delete de uma linha, sob o RLS.

-- =====================================================================
-- 1. Preparar boleto
-- =====================================================================

create function public.preparar_boleto()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.observacoes := nullif(btrim(new.observacoes), '');

  if new.data_pagamento is not null
     and new.data_pagamento > (now() at time zone 'America/Sao_Paulo')::date then
    raise exception 'A data do pagamento não pode ser no futuro.' using errcode = 'SC400';
  end if;

  return new;
end $$;

revoke execute on function public.preparar_boleto() from public, anon, authenticated;

create trigger boletos_preparar
  before insert or update of observacoes, data_pagamento on public.boletos
  for each row execute function public.preparar_boleto();

-- =====================================================================
-- 2. Resumo dos boletos
-- =====================================================================
-- Situação (pago, atrasado, vence hoje, pendente) é calculada no app a partir
-- de data_pagamento e data_vencimento; nada é gravado.

create view public.resumo_boletos
with (security_invoker = true) as
select b.id,
       b.fornecedor_id,
       f.nome  as fornecedor_nome,
       f.ativo as fornecedor_ativo,
       b.valor,
       b.data_vencimento,
       b.forma_pagamento,
       b.observacoes,
       b.comprovante_url,
       b.data_pagamento,
       b.created_at
  from public.boletos b
  join public.fornecedores f on f.consultora_id = b.consultora_id and f.id = b.fornecedor_id;

revoke all on public.resumo_boletos from anon, public;
grant select on public.resumo_boletos to authenticated;
