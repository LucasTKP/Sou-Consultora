-- Editar e excluir pagamentos de parcela, e editar o cronograma das parcelas (change `editar-pagamentos`)
-- 1. editar_pagamento: valor, forma, data e observação (nunca além do saldo da parcela).
-- 2. excluir_pagamento: apaga um pagamento lançado por engano.
-- 3. editar_parcelas: valor e vencimento de todas as parcelas da venda de uma vez.
--    Parcela com pagamento não muda valor nem vencimento; a soma continua igual ao total.

-- =====================================================================
-- 1. Editar pagamento
-- =====================================================================

create function public.editar_pagamento(
  p_pagamento_id uuid,
  p_valor        numeric,
  p_forma        text,
  p_data         date,
  p_observacao   text
) returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_pagamento     record;
  v_valor_parcela numeric(12, 2);
  v_saldo         numeric(12, 2);
  v_momento       timestamptz;
begin
  -- RLS: pagamento de outra consultora não é encontrado. Trava contra edição simultânea.
  select pp.id, pp.parcela_id, pp.data_pagamento
    into v_pagamento
    from public.pagamentos_parcela pp
   where pp.id = p_pagamento_id
     for update;
  if not found then
    raise exception 'Pagamento não encontrado.' using errcode = 'SC400';
  end if;

  select p.valor into v_valor_parcela
    from public.parcelas p
   where p.id = v_pagamento.parcela_id
     for update;

  if p_valor is null or p_valor <= 0 then
    raise exception 'Informe um valor maior que zero.' using errcode = 'SC400';
  end if;
  if p_forma is null or p_forma not in ('pix', 'cartao', 'dinheiro') then
    raise exception 'Escolha a forma de pagamento: Pix, cartão ou dinheiro.' using errcode = 'SC400';
  end if;
  if p_data is null or p_data > (now() at time zone 'America/Sao_Paulo')::date then
    raise exception 'A data do pagamento não pode ser no futuro.' using errcode = 'SC400';
  end if;

  -- O saldo considera os outros pagamentos da parcela (este sai da conta).
  select v_valor_parcela - coalesce(sum(pp.valor), 0)
    into v_saldo
    from public.pagamentos_parcela pp
   where pp.parcela_id = v_pagamento.parcela_id
     and pp.id <> p_pagamento_id;

  if p_valor > v_saldo then
    raise exception 'O valor não pode passar do saldo da parcela (R$ %).',
      replace(to_char(v_saldo, 'FM999999990.00'), '.', ',')
      using errcode = 'SC400';
  end if;

  -- Mesma data: mantém o horário original do pagamento.
  if p_data = (v_pagamento.data_pagamento at time zone 'America/Sao_Paulo')::date then
    v_momento := v_pagamento.data_pagamento;
  else
    v_momento := interno.momento_da_venda(p_data);
  end if;

  update public.pagamentos_parcela
     set valor = p_valor,
         forma_pagamento = p_forma,
         data_pagamento = v_momento,
         observacao = nullif(btrim(p_observacao), '')
   where id = p_pagamento_id;
end $$;

-- =====================================================================
-- 2. Excluir pagamento
-- =====================================================================

create function public.excluir_pagamento(p_pagamento_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  delete from public.pagamentos_parcela where id = p_pagamento_id;
  if not found then
    raise exception 'Pagamento não encontrado.' using errcode = 'SC400';
  end if;
end $$;

-- =====================================================================
-- 3. Editar parcelas da venda
-- =====================================================================
-- p_parcelas: [{"id": uuid, "valor": numeric, "data_vencimento": date}] com todas as parcelas da venda.

create function public.editar_parcelas(
  p_venda_id uuid,
  p_parcelas jsonb
) returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_total      numeric(12, 2);
  v_soma       numeric(12, 2);
  v_qtd        integer;
  v_linha      record;
  v_atual      record;
  v_pago       numeric(12, 2);
begin
  -- Trava a venda: duas edições ao mesmo tempo não misturam cronogramas.
  select v.total into v_total
    from public.vendas v
   where v.id = p_venda_id
     for update;
  if not found then
    raise exception 'Venda não encontrada.' using errcode = 'SC400';
  end if;

  if p_parcelas is null or jsonb_typeof(p_parcelas) <> 'array' then
    raise exception 'Confira as parcelas da venda.' using errcode = 'SC400';
  end if;

  select count(*)::integer into v_qtd
    from public.parcelas p
   where p.venda_id = p_venda_id;
  if jsonb_array_length(p_parcelas) <> v_qtd then
    raise exception 'Confira as parcelas da venda.' using errcode = 'SC400';
  end if;

  if exists (
    select 1
      from jsonb_to_recordset(p_parcelas) as x (id uuid, valor numeric, data_vencimento date)
     where x.id is null
        or x.valor is null or x.valor <= 0
        or x.data_vencimento is null
        or not exists (select 1 from public.parcelas p where p.id = x.id and p.venda_id = p_venda_id)
  ) then
    raise exception 'Cada parcela precisa de valor e data de vencimento.' using errcode = 'SC400';
  end if;

  for v_linha in
    select x.id, x.valor::numeric(12, 2) as valor, x.data_vencimento
      from jsonb_to_recordset(p_parcelas) as x (id uuid, valor numeric, data_vencimento date)
  loop
    select p.numero_parcela, p.valor, p.data_vencimento into v_atual
      from public.parcelas p
     where p.id = v_linha.id
       for update;

    select coalesce(sum(pp.valor), 0) into v_pago
      from public.pagamentos_parcela pp
     where pp.parcela_id = v_linha.id;

    -- Com pagamento, valor e vencimento ficam como estão (o valor já é >= o pago).
    if v_pago > 0 and (v_linha.valor <> v_atual.valor or v_linha.data_vencimento <> v_atual.data_vencimento) then
      raise exception 'Exclua os pagamentos da parcela % antes de alterar o valor ou o vencimento.',
        v_atual.numero_parcela
        using errcode = 'SC400';
    end if;
  end loop;

  select sum(x.valor::numeric(12, 2)) into v_soma
    from jsonb_to_recordset(p_parcelas) as x (valor numeric);
  if v_soma <> v_total then
    raise exception 'A soma das parcelas (R$ %) precisa ser igual ao total (R$ %).',
      replace(to_char(v_soma, 'FM999999990.00'), '.', ','),
      replace(to_char(v_total, 'FM999999990.00'), '.', ',')
      using errcode = 'SC400';
  end if;

  update public.parcelas p
     set valor = x.valor::numeric(12, 2),
         data_vencimento = x.data_vencimento
    from jsonb_to_recordset(p_parcelas) as x (id uuid, valor numeric, data_vencimento date)
   where p.id = x.id
     and p.venda_id = p_venda_id;
end $$;

-- =====================================================================
-- Permissões
-- =====================================================================

revoke execute on function public.editar_pagamento(uuid, numeric, text, date, text) from public, anon;
grant execute on function public.editar_pagamento(uuid, numeric, text, date, text) to authenticated;
revoke execute on function public.excluir_pagamento(uuid) from public, anon;
grant execute on function public.excluir_pagamento(uuid) to authenticated;
revoke execute on function public.editar_parcelas(uuid, jsonb) from public, anon;
grant execute on function public.editar_parcelas(uuid, jsonb) to authenticated;
