-- Código do produto único por consultora e marca (fornecedor).
-- Evita duplicar o mesmo produto, por exemplo ao importar duas vezes do catálogo.
-- Produto sem código continua livre (o código é opcional no cadastro manual).
-- A comparação ignora maiúsculas e espaços nas pontas: 'ABC ' e 'abc' são o mesmo código.

do $$
begin
  if exists (
    select 1
      from public.produtos
     where codigo is not null and btrim(codigo) <> ''
     group by consultora_id, fornecedor_id, lower(btrim(codigo))
    having count(*) > 1
  ) then
    raise exception 'Há produtos com o mesmo código na mesma marca. Corrija antes de aplicar esta migração.';
  end if;
end $$;

create unique index produtos_codigo_unico
  on public.produtos (consultora_id, fornecedor_id, lower(btrim(codigo)))
  where codigo is not null and btrim(codigo) <> '';
