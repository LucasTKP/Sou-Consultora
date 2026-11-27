-- Conta da consultora — Sou Consultora

-- =====================================================================
-- Categorias padrão: copiadas para cada nova consultora.
-- Não existe linha compartilhada entre consultoras (seguranca.md §2).
-- SECURITY INVOKER: o insert passa na policy porque new.id = auth.uid().
-- =====================================================================

create function public.criar_categorias_padrao()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  insert into public.categorias (consultora_id, nome, tipo, is_padrao)
  select new.id, padrao.nome, padrao.tipo, true
  from (values
    ('Perfumaria',           'produto'),
    ('Maquiagem',            'produto'),
    ('Cuidados com a pele',  'produto'),
    ('Cabelos',              'produto'),
    ('Corpo e banho',        'produto'),
    ('Infantil',             'produto'),
    ('Masculino',            'produto'),
    ('Presentes',            'produto'),
    ('Unhas',                'servico'),
    ('Maquiagem',            'servico'),
    ('Sobrancelha',          'servico'),
    ('Tratamento facial',    'servico'),
    ('Depilação',            'servico')
  ) as padrao (nome, tipo);

  return new;
end;
$$;

revoke execute on function public.criar_categorias_padrao() from public, anon, authenticated;

create trigger consultoras_categorias_padrao
  after insert on public.consultoras
  for each row execute function public.criar_categorias_padrao();

-- =====================================================================
-- Apagar a própria conta.
--
-- SECURITY DEFINER — justificativa (seguranca.md §4): o papel authenticated
-- não tem permissão em auth.users. A função só apaga o usuário da sessão
-- (auth.uid()), nunca recebe id por parâmetro, e o cascade
-- auth.users → consultoras → demais tabelas remove todos os dados.
-- Os arquivos do Storage são apagados pelo app antes desta chamada.
-- =====================================================================

create function public.apagar_minha_conta()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := auth.uid();
begin
  if v_id is null then
    raise exception 'Sessão obrigatória para apagar a conta.'
      using errcode = '42501';
  end if;

  delete from auth.users where id = v_id;
end;
$$;

revoke execute on function public.apagar_minha_conta() from public, anon;
grant execute on function public.apagar_minha_conta() to authenticated;
