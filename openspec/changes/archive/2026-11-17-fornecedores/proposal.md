# Proposal

## Why

Todo produto e todo lançamento de estoque pertencem a uma marca: no banco, `produtos.fornecedor_id` e `lancamentos_estoque.fornecedor_id` são obrigatórios. Hoje o módulo Fornecedores é uma tela "em construção", então a consultora não tem como cadastrar as marcas de quem compra. Sem isso não dá para começar a fase de Produtos. Fornecedores também é a base da fase de A pagar (boletos por marca).

## What Changes

- **Lista de fornecedores** (tela principal do módulo, aberta pelo menu lateral "Fornecedores & Marcas"):
  - busca pelo nome;
  - filtro por status: todos, ativo, em espera e vence hoje (calculado pelos boletos);
  - ordem por nome A-Z / Z-A e total cadastrado;
  - o card mostra iniciais, nome, quantos boletos estão em aberto e um selo de status;
  - o botão **Fornecedor** abre o cadastro.
- **Novo fornecedor:** nome (obrigatório), ramo, contato, telefone/WhatsApp e observações (fechamento de ciclo, pedido mínimo). **Salvar** grava e volta. **Cancelar** descarta.
- **Editar fornecedor:** o mesmo formulário, já preenchido, com o interruptor **Em espera**. Para deixar de usar uma marca, basta marcá-la em espera. Não existe exclusão: o botão "Excluir fornecedor" do design sai.
- **Detalhes do fornecedor:**
  - iniciais, nome, ramo, selo de status e "Parceiro desde" (mês e ano do cadastro);
  - resumo dos boletos: valor e quantidade em aberto, pagos e atrasados;
  - **Ver em A pagar**, que fica "em construção" até a fase de A pagar;
  - contato, telefone com o botão **WhatsApp** e observações;
  - **Editar fornecedor**.
- **Banco:**
  - telefone do fornecedor só com dígitos, como nas clientes;
  - nome único por consultora, sem diferenciar maiúsculas;
  - view de resumo por fornecedor com os números dos boletos (zerados enquanto não houver boletos) e o status calculado.
- **Fora do escopo:**
  - foto/logo e e-mail do fornecedor (estão no design, mas não no `fluxos.md` nem no banco);
  - a lista de boletos da marca e o cadastro de boletos (fase de A pagar);
  - apagar fornecedor.

## Capabilities

### New Capabilities
- `fornecedores`: cadastro, consulta e edição das marcas de quem a consultora compra, com status (ativo, em espera, vence hoje) e o resumo dos boletos de cada marca.

### Modified Capabilities
- (nenhuma). As regras de isolamento e integridade que já existem (`isolamento-de-dados`, `modelo-de-dados`, incluindo "fornecedor com boletos não é apagado") passam a valer também para a view nova, sem mudar os requisitos delas.

## Impact

- **Banco:**
  - nova migração `..._fornecedores.sql` com:
    - CHECK de formato do telefone;
    - índice único de nome por consultora;
    - view `resumo_fornecedores` (`security_invoker`).
  - testes pgTAP de formato, de nome duplicado, dos números da view com boletos de teste e de isolamento A × B × anon.
- **App:**
  - `core`: `dto`, `model`, `service` e `repository` de fornecedor;
  - `ServicoWhatsapp`, que já existe, é reaproveitado no telefone do fornecedor;
  - `ui/modules/fornecedores/` com as telas `lista`, `formulario` e `detalhes`;
  - rotas `/fornecedores/novo`, `/fornecedores/:id` e `/fornecedores/:id/editar`, abertas por cima da barra.
- **Dependências:** nenhuma nova.
- **Testes:**
  - unitários e de widget das camadas novas;
  - grupo E2E-05 no `integration_test/`, que roda só antes de lançar versão.
