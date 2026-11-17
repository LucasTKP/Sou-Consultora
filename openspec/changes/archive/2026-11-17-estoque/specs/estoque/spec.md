# Spec Delta

## Purpose

Permite à consultora registrar o que comprou em lotes e ver, por produto, o saldo para pronta entrega, o custo médio, o dinheiro parado em estoque, de onde veio cada lote e para quem saiu.

## ADDED Requirements

### Requirement: Resumo do estoque do produto
A aba **Estoque** dos detalhes do produto SHALL mostrar o saldo disponível (soma do disponível nos lotes), o selo "Pronta entrega" quando houver saldo ou "Esgotado" quando for zero, o custo médio e o valor em estoque. O custo médio MUST ser a média ponderada do custo unitário dos lotes com saldo, pela quantidade disponível. O valor em estoque MUST ser a soma de disponível × custo unitário. Nenhum desses números é gravado.

#### Scenario: Dois lotes com saldo
- **GIVEN** o produto tem um lote com 1 unidade disponível a R$ 124,80 e outro com 3 a R$ 155,00
- **WHEN** a consultora abre a aba Estoque
- **THEN** aparecem "4 unidades", "Pronta entrega", custo médio R$ 147,45 e valor em estoque R$ 589,80

#### Scenario: Sem lotes
- **GIVEN** o produto não tem lotes
- **WHEN** ela abre a aba Estoque
- **THEN** aparecem "0 unidades", "Esgotado", custo médio e valor em estoque R$ 0,00, e o convite para lançar estoque

### Requirement: Entradas (lotes) do produto
A aba Estoque SHALL listar os lotes do produto, do mais novo para o mais antigo, com número do lote (#01, #02…), data da compra, fornecedor, custo unitário, total pago (quantidade × custo), validade (quando houver) e a situação: "N un recebidas" quando nada saiu, "N un restante(s)" quando parte saiu e "Esgotado" quando nada resta.

#### Scenario: Lote parcialmente vendido
- **GIVEN** o lote #01 recebeu 2 unidades e 1 já saiu
- **WHEN** a lista de entradas é exibida
- **THEN** o lote mostra "1 un restante" e "1 de 2 vendida"

#### Scenario: Lote sem validade
- **GIVEN** o lote não tem validade
- **WHEN** a lista de entradas é exibida
- **THEN** a linha de validade não aparece

### Requirement: Saídas (vendas) do produto
A aba Estoque SHALL listar, da mais recente para a mais antiga, as vendas que consumiram o produto do estoque, com o nome da cliente, a data, as unidades e o valor do item. Sem saídas, MUST aparecer "Nenhuma venda ainda".

#### Scenario: Produto ainda não vendido
- **GIVEN** nenhuma venda consumiu o produto
- **WHEN** a consultora escolhe **Saídas (vendas)**
- **THEN** aparece "Nenhuma venda ainda"

#### Scenario: Produto vendido
- **GIVEN** a cliente Beatriz comprou 1 unidade por R$ 219,90 com baixa de estoque
- **WHEN** a lista de saídas é exibida
- **THEN** aparece Beatriz, a data da venda, "- 1 un" e R$ 219,90

### Requirement: Lançar estoque
O app SHALL registrar uma compra com a data (hoje por padrão) e um ou mais produtos, cada um com quantidade (≥ 1), custo unitário (obrigatório) e validade (opcional). O rodapé SHALL somar as unidades e o custo total. **Salvar lançamento** MUST gravar todos os lotes de uma vez (tudo ou nada) e voltar à tela de origem já atualizada. A data MUST NOT ser futura e a validade MUST NOT ser anterior à data da compra. Um produto MUST aparecer uma vez só por compra. Sem itens, **Salvar lançamento** MUST ficar desabilitado.

#### Scenario: Compra com dois produtos
- **WHEN** a consultora lança 3 "Kit Lily" a R$ 155,00 e 10 "Batom" a R$ 28,50 e salva
- **THEN** o rodapé mostrava 13 unidades e R$ 750,00, e cada produto ganha um lote novo

#### Scenario: Lançar a partir do produto
- **GIVEN** ela está na aba Estoque do "Kit Lily"
- **WHEN** ela toca em **Lançar Estoque**
- **THEN** a folha de item abre com o "Kit Lily" já escolhido e, depois de salvar, ela volta ao produto com o saldo atualizado

#### Scenario: Produto repetido
- **GIVEN** o "Kit Lily" já está na compra
- **WHEN** ela tenta adicioná-lo de novo
- **THEN** aparece o aviso de que o produto já está na compra e a folha não adiciona

#### Scenario: Falha ao salvar
- **GIVEN** não há internet
- **WHEN** ela salva o lançamento
- **THEN** aparece o aviso de erro, nenhum lote é gravado e os itens continuam na tela

#### Scenario: Cancelar com itens
- **GIVEN** a compra tem itens
- **WHEN** ela toca em **Cancelar**
- **THEN** o app pede confirmação antes de descartar

### Requirement: Margem prevista do item
A folha do item SHALL mostrar a margem prevista: preço de venda − custo unitário, em reais e em porcentagem do preço de venda, com o selo "Excelente" (≥ 25%), "Boa" (≥ 10% e < 25%), "Baixa" (≥ 0% e < 10%) ou "Prejuízo" (custo maior que o preço de venda).

#### Scenario: Margem excelente
- **GIVEN** o produto custa R$ 219,90 na venda
- **WHEN** ela informa o custo unitário R$ 155,00
- **THEN** aparece R$ 64,90 (29,5%) e "Excelente"

#### Scenario: Prejuízo
- **WHEN** o custo unitário é maior que o preço de venda
- **THEN** a margem aparece negativa com o selo "Prejuízo"

### Requirement: Fornecedor e numeração dos lotes
Cada lote MUST ser do fornecedor (marca) do próprio produto. Uma compra com produtos de marcas diferentes MUST virar um lançamento por marca, todos com a mesma data. O número do lote MUST ser sequencial por produto (o maior número já usado + 1), também quando dois lançamentos acontecem ao mesmo tempo.

#### Scenario: Compra com duas marcas
- **WHEN** a consultora lança um produto da Natura e um do Boticário na mesma compra
- **THEN** o banco grava dois lançamentos (um por marca) com a mesma data, e cada lote mostra o fornecedor certo

#### Scenario: Segundo lote do produto
- **GIVEN** o produto já tem o lote #01
- **WHEN** ela lança estoque dele de novo
- **THEN** o lote novo é o #02

### Requirement: Apagar lote sem vendas
Na lista de entradas, o app SHALL oferecer apagar um lote que nunca teve saída, com confirmação. O banco MUST recusar apagar um lote que já teve saída. Quando o lançamento do lote ficar sem nenhum lote, o lançamento MUST ser apagado junto.

#### Scenario: Lote lançado por engano
- **GIVEN** o lote #02 não teve nenhuma venda
- **WHEN** a consultora apaga o lote e confirma
- **THEN** o lote some, o saldo diminui e a lista de produtos se atualiza

#### Scenario: Lote com venda
- **GIVEN** o lote #01 já teve uma saída
- **WHEN** a lista de entradas é exibida
- **THEN** o lote não oferece a opção de apagar, e o banco recusaria a exclusão

### Requirement: Isolamento do estoque
Lançamentos, lotes, saídas e as views de estoque MUST respeitar o isolamento por consultora: a consultora A nunca lê, lança nem apaga estoque da consultora B, não lança lote em produto de B, e o usuário anônimo não acessa nada nem executa as funções de estoque.

#### Scenario: Lançar em produto de outra consultora
- **GIVEN** A conhece o id de um produto de B
- **WHEN** A chama o lançamento com esse produto
- **THEN** o banco recusa e nada é gravado

#### Scenario: Apagar lote de outra consultora
- **WHEN** A tenta apagar um lote de B
- **THEN** o banco recusa e o lote de B continua igual

#### Scenario: Ler estoque de outra consultora
- **WHEN** A consulta os lotes e as saídas
- **THEN** só aparecem os lotes e as saídas de A

#### Scenario: Anônimo
- **WHEN** o usuário anônimo consulta as views ou chama as funções de estoque
- **THEN** o banco recusa
