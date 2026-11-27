-- Clientes — Sou Consultora (change `clientes`)
-- 1. Formatos: WhatsApp só com dígitos (DDD + 8 ou 9) e nascimento não futuro.
-- 2. View `resumo_clientes`: números financeiros por cliente (security_invoker → herda o RLS).
-- 3. RPC `salvar_cliente`: grava cliente + endereço numa transação (security invoker, sem consultora_id).

-- =====================================================================
-- 1. Formatos
-- =====================================================================

alter table public.clientes
  add constraint clientes_whatsapp_digitos check (whatsapp ~ '^[0-9]{10,11}$'),
  add constraint clientes_nascimento_passado check (data_nascimento is null or data_nascimento <= current_date);

create index clientes_nome_idx on public.clientes (consultora_id, nome);

-- =====================================================================
-- 2. Resumo financeiro por cliente
-- =====================================================================
-- "Hoje" é o dia em São Paulo, o mesmo que a consultora vê no aparelho.
-- Saldo de uma parcela = valor − pagamentos; só conta quando > 0.

create view public.resumo_clientes
with (security_invoker = true) as
with
  hoje as (
    select (now() at time zone 'America/Sao_Paulo')::date as dia
  ),
  saldo_parcelas as (
    select v.cliente_id,
           p.data_vencimento,
           p.valor - coalesce((select sum(pp.valor)
                                 from public.pagamentos_parcela pp
                                where pp.parcela_id = p.id), 0) as saldo
      from public.parcelas p
      join public.vendas v on v.id = p.venda_id
  ),
  financeiro as (
    select sp.cliente_id,
           sum(sp.saldo) filter (where sp.saldo > 0) as saldo_devedor,
           sum(sp.saldo) filter (where sp.saldo > 0 and sp.data_vencimento < h.dia) as valor_atrasado,
           sum(sp.saldo) filter (where sp.saldo > 0 and sp.data_vencimento = h.dia) as valor_vence_hoje
      from saldo_parcelas sp
     cross join hoje h
     group by sp.cliente_id
  ),
  compras as (
    select v.cliente_id,
           count(*)          as qtd_compras,
           sum(v.total)      as total_compras,
           max(v.data_venda) as ultima_compra
      from public.vendas v
     group by v.cliente_id
  )
select c.id,
       c.nome,
       c.whatsapp,
       c.data_nascimento,
       c.created_at,
       coalesce(co.qtd_compras, 0)::integer       as qtd_compras,
       coalesce(co.total_compras, 0)::numeric(12, 2)   as total_compras,
       co.ultima_compra,
       coalesce(f.saldo_devedor, 0)::numeric(12, 2)    as saldo_devedor,
       coalesce(f.valor_atrasado, 0)::numeric(12, 2)   as valor_atrasado,
       coalesce(f.valor_vence_hoje, 0)::numeric(12, 2) as valor_vence_hoje
  from public.clientes c
  left join compras co   on co.cliente_id = c.id
  left join financeiro f on f.cliente_id = c.id;

revoke all on public.resumo_clientes from anon, public;
grant select on public.resumo_clientes to authenticated;

-- =====================================================================
-- 3. Gravar cliente + endereço
-- =====================================================================
-- p_id nulo → cria; senão edita (id de outra consultora some pelo RLS → erro).
-- p_endereco nulo (ou só com campos vazios) → cliente fica sem endereço e o antigo é apagado.
-- Campos de texto vazios viram null.

create or replace function public.salvar_cliente(
  p_id              uuid,
  p_nome            text,
  p_whatsapp        text,
  p_data_nascimento date,
  p_observacoes     text,
  p_endereco        jsonb
) returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_id          uuid := p_id;
  v_endereco_id uuid;
  v_tem_endereco boolean;
begin
  v_tem_endereco := p_endereco is not null and exists (
    select 1
      from jsonb_each_text(p_endereco) e
     where e.key in ('cep', 'rua', 'numero', 'complemento', 'bairro', 'cidade', 'uf', 'referencia')
       and nullif(btrim(e.value), '') is not null
  );

  if v_id is null then
    insert into public.clientes (nome, whatsapp, data_nascimento, observacoes)
    values (btrim(p_nome), p_whatsapp, p_data_nascimento, nullif(btrim(p_observacoes), ''))
    returning id into v_id;
  else
    update public.clientes
       set nome            = btrim(p_nome),
           whatsapp        = p_whatsapp,
           data_nascimento = p_data_nascimento,
           observacoes     = nullif(btrim(p_observacoes), '')
     where id = v_id
    returning endereco_id into v_endereco_id;

    if not found then
      raise exception 'cliente não encontrada' using errcode = 'P0002';
    end if;
  end if;

  if not v_tem_endereco then
    if v_endereco_id is not null then
      update public.clientes set endereco_id = null where id = v_id;
      delete from public.enderecos where id = v_endereco_id;
    end if;
    return v_id;
  end if;

  if v_endereco_id is null then
    insert into public.enderecos default values returning id into v_endereco_id;
    update public.clientes set endereco_id = v_endereco_id where id = v_id;
  end if;

  update public.enderecos
     set cep         = nullif(btrim(p_endereco ->> 'cep'), ''),
         rua         = nullif(btrim(p_endereco ->> 'rua'), ''),
         numero      = nullif(btrim(p_endereco ->> 'numero'), ''),
         complemento = nullif(btrim(p_endereco ->> 'complemento'), ''),
         bairro      = nullif(btrim(p_endereco ->> 'bairro'), ''),
         cidade      = nullif(btrim(p_endereco ->> 'cidade'), ''),
         uf          = upper(nullif(btrim(p_endereco ->> 'uf'), '')),
         referencia  = nullif(btrim(p_endereco ->> 'referencia'), '')
   where id = v_endereco_id;

  return v_id;
end $$;

revoke execute on function public.salvar_cliente(uuid, text, text, date, text, jsonb) from public, anon;
grant execute on function public.salvar_cliente(uuid, text, text, date, text, jsonb) to authenticated;
