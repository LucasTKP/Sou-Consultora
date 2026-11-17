# modelo-de-dados Specification

## Purpose
Define as entidades da consultora (clientes, catálogo, estoque, vendas, cobranças e boletos) e as regras de integridade que o banco garante independentemente do app.

## Requirements

### Requirement: Entidades da consultora
O sistema SHALL armazenar consultoras, clientes, endereços, fornecedores, categorias, produtos, serviços, lançamentos de estoque, lotes, vendas, itens de venda, parcelas, pagamentos de parcela, saídas de estoque e boletos, conforme `banco-de-dados.md`.

#### Scenario: Estrutura disponível
- **WHEN** as migrações são aplicadas em um banco vazio
- **THEN** as 15 entidades existem com os campos e obrigatoriedades descritos em `banco-de-dados.md`

### Requirement: Item de venda é produto ou serviço
O sistema MUST exigir que cada item de venda referencie exatamente um produto ou exatamente um serviço.

#### Scenario: Item com produto e serviço
- **WHEN** um item é gravado com produto e serviço preenchidos
- **THEN** o banco recusa a gravação

#### Scenario: Item sem produto nem serviço
- **WHEN** um item é gravado sem produto e sem serviço
- **THEN** o banco recusa a gravação

### Requirement: Serviço não baixa estoque
O sistema MUST recusar item de serviço marcado para baixar estoque.

#### Scenario: Serviço com baixa de estoque
- **WHEN** um item de serviço é gravado com baixa de estoque ligada
- **THEN** o banco recusa a gravação

### Requirement: Valores e quantidades válidos
O sistema MUST recusar preços, custos, descontos e valores negativos, e quantidades menores ou iguais a zero em itens, lotes, saídas e parcelas.

#### Scenario: Preço negativo
- **WHEN** um produto é gravado com preço de venda negativo
- **THEN** o banco recusa a gravação

#### Scenario: Quantidade zero no item
- **WHEN** um item de venda é gravado com quantidade 0
- **THEN** o banco recusa a gravação

### Requirement: Saldo do lote dentro do recebido
O sistema MUST manter a quantidade disponível de cada lote entre zero e a quantidade recebida.

#### Scenario: Saldo negativo
- **WHEN** a quantidade disponível de um lote é alterada para menos que zero
- **THEN** o banco recusa a alteração

#### Scenario: Saldo maior que o recebido
- **WHEN** um lote de 3 unidades recebidas é gravado com 4 disponíveis
- **THEN** o banco recusa a gravação

### Requirement: Durabilidade do produto entre 30 e 180 dias
O sistema MUST aceitar a durabilidade do produto vazia ou entre 30 e 180 dias.

#### Scenario: Durabilidade fora da faixa
- **WHEN** um produto é gravado com durabilidade de 10 dias
- **THEN** o banco recusa a gravação

### Requirement: Formas de pagamento válidas
O sistema MUST aceitar como forma de pagamento de parcela somente pix, cartão ou dinheiro, e de boleto somente pix, boleto ou transferência.

#### Scenario: Forma desconhecida
- **WHEN** um pagamento de parcela é gravado com forma "cheque"
- **THEN** o banco recusa a gravação

### Requirement: Numeração única
O sistema MUST garantir código de venda único por consultora, número de parcela único por venda e número de lote único por produto.

#### Scenario: Código de venda repetido
- **GIVEN** A já tem a venda de código 12
- **WHEN** outra venda de A é gravada com código 12
- **THEN** o banco recusa a gravação

#### Scenario: Mesmo código em consultoras diferentes
- **GIVEN** A tem a venda de código 1
- **WHEN** B grava uma venda de código 1
- **THEN** a gravação é aceita

### Requirement: Remoção em cascata da venda
O sistema SHALL remover itens, parcelas, pagamentos e saídas de estoque quando a venda for apagada.

#### Scenario: Apagar venda
- **GIVEN** uma venda com 2 itens, 2 parcelas, 1 pagamento e 1 saída de estoque
- **WHEN** a venda é apagada
- **THEN** nenhum desses registros permanece

### Requirement: Cadastros em uso não são apagados
O sistema MUST impedir apagar cliente, produto, serviço, fornecedor, categoria ou lote que esteja referenciado por outro registro.

#### Scenario: Apagar produto vendido
- **GIVEN** um produto que aparece em uma venda
- **WHEN** a consultora tenta apagar o produto
- **THEN** o banco recusa a remoção

#### Scenario: Apagar fornecedor com boletos
- **GIVEN** um fornecedor com boletos
- **WHEN** a consultora tenta apagar o fornecedor
- **THEN** o banco recusa a remoção
