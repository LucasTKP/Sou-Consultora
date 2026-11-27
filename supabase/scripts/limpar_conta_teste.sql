-- Remove só o que `popular_conta_teste.sql` criou (marcador '[seed]').
-- Dados que você cadastrou à mão ficam. Não zera `ultimo_codigo_venda`.
-- Se você usou produto/cliente seed em uma venda real, o delete correspondente
-- falha por FK: apague ou edite essa venda antes.

do $limpar$
declare
  v_id uuid := 'a9e1f1b3-4b5d-4189-96a5-5f50ba472d57';
begin
  -- Vendas levam itens, parcelas, pagamentos e saídas junto (cascade).
  delete from public.vendas   where consultora_id = v_id and observacoes like '[seed]%';
  delete from public.boletos  where consultora_id = v_id and observacoes like '[seed]%';

  delete from public.lotes_estoque
   where consultora_id = v_id
     and produto_id in (select id from public.produtos where consultora_id = v_id and observacoes like '[seed]%');
  delete from public.lancamentos_estoque l
   where l.consultora_id = v_id
     and l.fornecedor_id in (select id from public.fornecedores where consultora_id = v_id and observacoes like '[seed]%')
     and not exists (select 1 from public.lotes_estoque x where x.lancamento_id = l.id);

  delete from public.produtos  where consultora_id = v_id and observacoes like '[seed]%';
  delete from public.servicos  where consultora_id = v_id and observacoes like '[seed]%';
  delete from public.clientes  where consultora_id = v_id and observacoes like '[seed]%';
  delete from public.enderecos where consultora_id = v_id and referencia = '[seed]';
  delete from public.fornecedores where consultora_id = v_id and observacoes like '[seed]%';
end
$limpar$;
