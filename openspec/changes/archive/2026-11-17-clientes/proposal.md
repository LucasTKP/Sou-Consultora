# Proposal

## Why

A consultora vende para as próprias clientes, mas hoje o módulo Clientes é uma tela "em construção". Sem a carteira de clientes cadastrada (contato, aniversário, preferências e endereço de entrega), ela não consegue registrar vendas nem cobrar. Clientes é a base das fases de Vendas e A receber, por isso vem agora.

## What Changes

- **Lista de clientes** (tela principal do módulo, na barra): busca por nome, filtro (todas, em dia, com saldo, aniversariantes), ordem A-Z / Z-A, total cadastrado e um selo de situação por cliente ("Deve R$", "Vence hoje R$", "Aniversário", "Em dia"). **Novo cliente** abre o cadastro.
- **Novo cliente em 2 passos:**
  - passo 1: nome e WhatsApp obrigatórios; nascimento e observações opcionais;
  - passo 2 (opcional): endereço de entrega, com preenchimento automático pelo CEP (ViaCEP).
- **Editar cliente:** reaproveita os 2 passos, já preenchidos. Não existe tela própria de edição.
- **Detalhes do cliente:** iniciais, nome, selo do saldo devedor e as saídas **Dados cadastrais**, **Compras da cliente** e **Nova venda**. As duas últimas ficam "em construção" até a fase de Vendas.
- **Dados cadastrais:** leitura de todos os dados, **Abrir WhatsApp** e **Editar**.
- **Banco:**
  - WhatsApp da cliente só com dígitos (como o da consultora);
  - UF da cliente opcional, mas válida;
  - view de resumo com saldo devedor, valor atrasado, valor que vence hoje, total de compras e data da última compra (zerados enquanto não houver vendas);
  - função que grava cliente e endereço juntos, de forma atômica.
- **Fora do escopo:**
  - a tela Compras da cliente e a Nova venda (fase de Vendas);
  - apagar cliente (não há essa ação nas telas, e uma cliente com venda não pode ser apagada);
  - o lembrete de recompra (fase de Produtos/Vendas).

## Capabilities

### New Capabilities
- `clientes`: cadastro, consulta, edição e situação financeira resumida das clientes da consultora, incluindo endereço de entrega e contato por WhatsApp.

### Modified Capabilities
- (nenhuma). As regras de isolamento e integridade já existentes (`isolamento-de-dados`, `modelo-de-dados`) passam a valer também para a view e a função novas, sem mudar os requisitos delas.

## Impact

- **Banco:**
  - nova migração `..._clientes.sql`, com:
    - CHECK de formato;
    - view `resumo_clientes` (`security_invoker`);
    - RPC `salvar_cliente` (`security invoker`, sem `consultora_id`).
  - testes pgTAP de formato, de RPC e de isolamento A × B × anon.
- **App:**
  - `core`: `dto`, `model`, `service` e `repository` de cliente; serviço de CEP.
  - `ui/modules/clientes/` com as telas `lista`, `formulario` (2 passos), `detalhes` e `dados`.
  - Rotas `/clientes/novo`, `/clientes/:id`, `/clientes/:id/dados` e `/clientes/:id/editar`, abertas por cima da barra.
- **Dependências:**
  - `url_launcher` (nova), para abrir o WhatsApp;
  - `http` (já existe), para o ViaCEP.
- **Externo:** só o CEP é enviado ao ViaCEP. Nenhum dado de cliente sai do app.
- **Testes:**
  - unitários e de widget das camadas novas;
  - grupo E2E-04 no `integration_test/`, que roda só antes de lançar versão.
