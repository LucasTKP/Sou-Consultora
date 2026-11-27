-- Parcela com pagamento pode mudar valor e vencimento.
-- O valor novo não pode ficar abaixo do que já foi recebido.

create or replace function public.editar_parcelas(
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

    if v_linha.valor < v_pago then
      raise exception 'O valor da parcela % não pode ser menor que o já recebido (R$ %).',
        v_atual.numero_parcela,
        replace(to_char(v_pago, 'FM999999990.00'), '.', ',')
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
