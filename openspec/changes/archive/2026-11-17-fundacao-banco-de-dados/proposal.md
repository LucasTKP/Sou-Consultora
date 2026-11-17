# Proposal

## Why

Nenhuma funcionalidade da consultora (clientes, produtos, estoque, vendas, cobranças) pode ser construída sem o banco. Hoje não existe schema nem migração versionada no repositório. Criar todas as tabelas de uma vez, com o isolamento por consultora já garantido e testado, evita retrabalho e impede que uma falha de segurança entre "para corrigir depois".

## What Changes

- Inicializa o Supabase no repositório (`supabase/`), com migrações versionadas e ambiente local (Docker) para testar.
- Cria as 15 tabelas de `banco-de-dados.md`, já com as decisões do produto:
  - `consultora_id NOT NULL DEFAULT auth.uid()` em todas;
  - FKs compostas `(consultora_id, x_id)`;
  - CHECKs de integridade (produto **ou** serviço no item, valores não negativos, saldo do lote entre 0 e o recebido, durabilidade de 30 a 180 dias, formas de pagamento válidas).
- Liga e força o RLS em todas as tabelas, com 4 policies por `auth.uid()` só para `authenticated`. O papel `anon` perde qualquer acesso.
- Cria um trigger: quando a consultora é cadastrada, as categorias padrão (produto e serviço) são copiadas para ela.
- Garante a exclusão em cascata: apagar o usuário do Auth apaga a consultora e todos os dados dela.
- Cria os buckets privados `fotos` e `comprovantes`, com acesso só à pasta `<auth.uid()>/`.
- Adiciona testes pgTAP que provam o isolamento A × B × anon em todas as tabelas e buckets.
- **Fora do escopo:** as RPCs de negócio (`concluir_venda`, `lancar_estoque`, `cancelar_venda`, `editar_venda`, `registrar_pagamento`) e as views de indicadores. Elas entram junto das fases que as usam, seguindo as mesmas regras.

## Capabilities

### New Capabilities
- `isolamento-de-dados`: garante que cada consultora só lê, grava e referencia os próprios dados (tabelas e arquivos) e que usuários anônimos não acessam nada.
- `modelo-de-dados`: estrutura e integridade dos dados da consultora — entidades, obrigatoriedades, relações e restrições que o banco recusa.
- `conta-da-consultora`: ciclo de vida da conta no banco — criação do registro da consultora com categorias padrão e remoção total dos dados ao apagar a conta.

### Modified Capabilities
<!-- Nenhuma: ainda não há specs no projeto. -->

## Impact

- **Novo:** `supabase/config.toml`, `supabase/migrations/*.sql`, `supabase/seed.sql`, `supabase/tests/*.sql`.
- **Ambiente:** exige Docker para rodar o Supabase local e os testes (`supabase test db`). Aplicar no projeto remoto (`supabase db push`) é um passo manual, confirmado pelo dono do projeto.
- **App Flutter:** nenhuma mudança de código nesta change. Os DTOs serão criados por feature nas próximas fases, espelhando este schema.
- **Documentação:** `banco-de-dados.md` continua sendo a referência do produto. As migrações passam a ser a fonte da verdade técnica.
