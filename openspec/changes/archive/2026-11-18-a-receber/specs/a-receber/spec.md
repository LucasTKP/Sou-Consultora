# Spec Delta

## Purpose

Permite à consultora acompanhar, parcela por parcela, o dinheiro que as clientes devem, registrar cada recebimento (inteiro ou parcial) e enviar o comprovante.

## ADDED Requirements

### Requirement: Listar recebimentos
O app SHALL mostrar, em A receber, as parcelas com vencimento no mês escolhido (padrão: mês atual; opção "Todos os meses") em cards com iniciais e nome da cliente, qual parcela ("Parcela 2/2" ou "Parcela única"), o selo de situação ("Atrasado (dd/mm)", "Vence hoje", "Venc. dd/mm" ou "Pago em dd/mm") e o valor (o saldo, se não estiver paga), com a quantidade encontrada. SHALL buscar por cliente ou produto/serviço (sem acento), filtrar por status (Todos, A receber, Atrasado, Vence hoje, Pago, com contagens) e ordenar por vencimento ou valor.

#### Scenario: Parcela vencida
- **GIVEN** a parcela 2/2 venceu em 15/10 sem pagamento
- **WHEN** a consultora abre A receber em outubro
- **THEN** o card mostra "Atrasado (15/10)" e o saldo

#### Scenario: Busca pelo produto
- **WHEN** ela digita "lily"
- **THEN** aparecem só as parcelas de vendas com "Kit Lily"

### Requirement: Detalhes da parcela
O app SHALL mostrar o saldo em aberto, quanto já entrou e quanto resta, o valor da parcela, o vencimento (com há quantos dias venceu), a cliente com telefone e **Cobrar** (WhatsApp com a mensagem da parcela), os pagamentos desta parcela (valor, forma, data), a venda de origem (que abre os detalhes da venda) e as outras parcelas da mesma venda (que abrem a parcela escolhida). **Pagar** SHALL aparecer só com saldo. **Mais opções** SHALL oferecer cobrar, gerar recibo (com pagamento) e cancelar a venda.

#### Scenario: Pagamento parcial
- **GIVEN** a parcela de R$ 120,00 recebeu R$ 50,00
- **WHEN** ela abre os detalhes
- **THEN** aparecem saldo R$ 70,00, "Pago R$ 50,00", "Resta R$ 70,00" e o pagamento de R$ 50,00

### Requirement: Registrar pagamento
A folha **Registrar pagamento** SHALL vir com o saldo restante no valor (editável para pagamento parcial), a forma (Pix, cartão ou dinheiro), a data (hoje) e observação opcional. O valor MUST ser maior que zero e MUST NOT passar do saldo; a data MUST NOT ser futura. **Confirmar** SHALL gravar o pagamento e abrir o comprovante.

#### Scenario: Valor maior que o saldo
- **GIVEN** o saldo é R$ 70,00
- **WHEN** ela informa R$ 80,00
- **THEN** a folha avisa e não grava

#### Scenario: Quita a parcela
- **WHEN** ela confirma o saldo inteiro no Pix
- **THEN** a parcela fica paga e aparece o comprovante "Parcela 2 de 2 • Quitada"

### Requirement: Comprovante de pagamento
O comprovante SHALL mostrar "Pagamento confirmado", o valor pago, a data e a hora, o nome e a chave Pix da consultora (quando houver), a cliente, a forma de pagamento, a parcela e se ficou quitada ou parcial, a venda (código, data, itens, número de parcelas, total), as parcelas da venda e o saldo restante da venda. **Compartilhar** SHALL enviar a imagem do comprovante com uma descrição curta (cliente, valor, parcela e saldo).

#### Scenario: Pagamento com data retroativa
- **GIVEN** a parcela já tem um pagamento de hoje
- **WHEN** ela registra outro pagamento com a data de ontem
- **THEN** o comprovante que abre é o desse pagamento, não o de hoje

#### Scenario: Compartilhar
- **WHEN** ela toca em Compartilhar
- **THEN** o celular abre o compartilhamento com a imagem do comprovante e o texto curto

### Requirement: Integridade dos pagamentos
A função `registrar_pagamento` MUST recusar valor ≤ 0, valor maior que o saldo da parcela, forma inválida, data futura e parcela inexistente ou de outra consultora, sem gravar nada.

#### Scenario: Pagamento além do saldo
- **WHEN** alguém registra R$ 200,00 numa parcela com saldo de R$ 120,00
- **THEN** o banco recusa com a mensagem do saldo

### Requirement: Isolamento dos recebimentos
Parcelas, pagamentos, as views e a função de pagamento MUST respeitar o isolamento por consultora: A nunca lê nem paga parcelas de B, e o anônimo não acessa nada.

#### Scenario: Pagar parcela de outra consultora
- **WHEN** A chama `registrar_pagamento` com a parcela de B
- **THEN** o banco recusa e nada é gravado

#### Scenario: Anônimo
- **WHEN** o anônimo lê os pagamentos ou chama a função
- **THEN** o banco recusa
