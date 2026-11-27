# Proposal

## Why

O catálogo de produtos já existe, mas todo produto aparece como "Esgotado": a consultora ainda não consegue registrar o que comprou. Sem estoque, ela não sabe o que tem para pronta entrega, quanto dinheiro está parado nem o custo real do que vende. A fase de Vendas depende disso, porque a venda com baixa consome os lotes (o mais antigo primeiro) e grava o custo a partir deles.

## What Changes

- **Aba Estoque nos detalhes do produto** (ao lado de **Informações**, com a quantidade disponível no rótulo):
  - saldo disponível em unidades, com o selo "Pronta entrega" (tem saldo) ou "Esgotado";
  - custo médio (média ponderada dos lotes com saldo) e valor em estoque (Σ disponível × custo unitário);
  - **Entradas (lotes)**, do mais novo para o mais antigo:
    - número do lote (#01, #02…), data da compra e fornecedor;
    - custo unitário, total pago e validade;
    - quantas unidades ainda restam;
    - lote sem nenhuma venda pode ser **apagado**, com confirmação;
  - **Saídas (vendas)**: cliente, data, unidades e valor de cada venda que consumiu o produto. Até a fase de Vendas a lista fica vazia, com o aviso "Nenhuma venda ainda";
  - **Lançar Estoque** abre o lançamento com o produto já escolhido; salvar volta ao produto atualizado.
- **Lançar Estoque** (tela por cima, sem a barra):
  - data da compra (hoje por padrão, nunca no futuro);
  - lista de produtos da compra, cada um com quantidade e total;
  - **Adicionar outro produto** abre a folha de item;
  - **Cadastrar novo produto** abre o cadastro e, na volta, o produto novo aparece na folha;
  - rodapé com o total de unidades e o custo total da compra;
  - **Salvar lançamento** grava tudo de uma vez; **Cancelar** e a seta descartam (com confirmação se já houver itens).
- **Folha "Adicionar Produto ao Estoque":**
  - produto (com busca), preço de venda e estoque atual dele;
  - quantidade (mínimo 1), custo unitário (obrigatório) e validade do lote (opcional, nunca no passado);
  - margem prevista em reais e em porcentagem, com o selo "Excelente" (≥ 25%), "Boa" (10% a 25%), "Baixa" (< 10%) ou "Prejuízo" (custo maior que o preço de venda);
  - **Adicionar à compra** inclui o item; **Voltar sem adicionar** fecha;
  - tocar num item já incluído reabre a folha para alterar ou **Remover da compra**.
- **Lista de produtos:** ganha o atalho **Lançar estoque**, que abre o lançamento vazio e volta à lista.
- **Fornecedor do lote:** não existe campo de fornecedor no lançamento. Cada lote é do fornecedor (marca) do próprio produto. Uma compra com produtos de marcas diferentes vira um lançamento por marca, todos com a mesma data.
- **Banco:**
  - função `lancar_estoque`, tudo ou nada: cria os lançamentos por marca e os lotes com número sequencial por produto;
  - função `apagar_lote`: apaga o lote só se ele nunca teve saída, e o lançamento junto se ficar vazio;
  - views do estoque por produto (resumo, lotes com o fornecedor e saídas por venda), todas `security_invoker`.
- **Fora do escopo:**
  - editar um lote (corrigir é apagar e lançar de novo);
  - boleto da compra (fase de A pagar);
  - tocar numa saída para abrir a venda (fase de Vendas);
  - atualizar o preço de custo de referência do produto a partir do lote.

## Capabilities

### New Capabilities
- `estoque`: lançamento de compras em lotes, saldo, custo médio, valor parado, entradas e saídas por produto, e exclusão de lote sem vendas.

### Modified Capabilities
- `produtos`: os detalhes do produto ganham a aba **Estoque** (antes só **Informações**) e a lista ganha o atalho **Lançar estoque**.

## Impact

- **Banco:**
  - nova migração `..._estoque.sql` com as funções `lancar_estoque` e `apagar_lote` (`security invoker`, sem `consultora_id` como parâmetro, `execute` só para `authenticated`) e as views do estoque;
  - testes pgTAP de numeração dos lotes, separação por marca, tudo ou nada, data futura recusada, exclusão de lote com e sem saída e isolamento A × B × anon.
- **App:**
  - `core`: `dto`, `model`, `service` e `repository` de estoque;
  - `ui/modules/produtos/detalhes/` ganha a aba Estoque;
  - nova tela `ui/modules/produtos/lancar_estoque/` com a folha de item;
  - rota `/produtos/lancar-estoque` (com `?produto=<id>` opcional), aberta por cima da barra.
- **Dependências:** nenhuma nova.
- **Testes:**
  - unitários e de widget das camadas novas;
  - grupo E2E-07 no `integration_test/`.
