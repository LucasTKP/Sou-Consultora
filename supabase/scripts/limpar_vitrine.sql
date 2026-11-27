-- Remove só o que `popular_vitrine.sql` criou (ids começando em '5eed0000-').
do $limpar$
declare
  v_id uuid := '0f76794d-cebd-458b-9166-15f8f407d45f';
  t    text;
begin
  -- Ordem respeita as FKs; vendas levam itens, parcelas, pagamentos e saídas.
  foreach t in array array['vendas','boletos','lotes_estoque','lancamentos_estoque','produtos',
                           'servicos','clientes','enderecos','fornecedores'] loop
    execute format('delete from public.%I where consultora_id = $1 and id::text like ''5eed0000-%%''', t) using v_id;
  end loop;
end
$limpar$;
