# vendas Specification

## Purpose

Permite à consultora registrar pedidos de produtos e serviços, combinar como a cliente vai pagar, baixar o estoque do lote mais antigo e acompanhar, editar ou cancelar cada venda.

## Requirements

### Requirement: Listar vendas
O app SHALL mostrar, na tela Vendas (item da barra), as vendas do mês escolhido (padrão: mês atual; opção "Todos os meses") em cards com iniciais e nome da cliente, quando ("Hoje • 14:30", "Ontem • 16:45" ou "12/11 • 11:20"), quantidade de itens, total e status, com o total de vendas exibidas. SHALL buscar por cliente, produto/serviço ou código (sem acento), filtrar por status (Em aberto, Atrasada, Quitada, com contagens) e ordenar por data (mais recentes ou mais antigas).

#### Scenario: Busca pelo código
- **WHEN** a consultora digita "12"
- **THEN** aparece a venda #0012

#### Scenario: Lista vazia
- **GIVEN** não há vendas no mês
- **WHEN** ela abre Vendas
- **THEN** aparece o convite para registrar a primeira venda

### Requirement: Status da venda
O status MUST ser calculado das parcelas e pagamentos, nunca gravado: "Quitada" quando todas as parcelas estão pagas, "Atrasada" quando alguma parcela vencida (antes de hoje) tem saldo, "Em aberto" no resto. Cada parcela SHALL aparecer como "Pago", "Parcial" (pagou parte), "Atrasada" (vencida com saldo) ou "A receber".

#### Scenario: Parcela vencida
- **GIVEN** a 2ª parcela venceu ontem sem pagamento
- **WHEN** a venda é exibida
- **THEN** a venda aparece "Atrasada"

### Requirement: Montar o pedido (passo 1)
O passo 1 SHALL pedir a cliente (obrigatória, com busca e atalho para cadastrar) e um ou mais itens. A folha do item SHALL alternar entre Produto e Serviço, escolher o item do catálogo, a quantidade (≥ 1) e o desconto em R$ (opcional, até o subtotal do item), mostrando valor unitário, desconto e subtotal. O preço MUST ser o do catálogo. Para produto, **Baixar do estoque** SHALL vir ligado: ligado, a quantidade MUST NOT passar do saldo ("Estoque insuficiente: X un disponíveis"); desligado, o item não mexe no estoque. Um mesmo produto ou serviço MUST aparecer uma vez só no pedido. O rodapé SHALL somar subtotal, descontos e total. **Avançar** MUST exigir cliente, ao menos um item e total maior que zero.

#### Scenario: Estoque insuficiente
- **GIVEN** o produto tem 2 un disponíveis
- **WHEN** ela pede 3 com Baixar do estoque ligado
- **THEN** aparece "Estoque insuficiente: 2 un disponíveis" e Salvar fica bloqueado

#### Scenario: Encomenda
- **WHEN** ela desliga Baixar do estoque
- **THEN** pode pedir qualquer quantidade e o item entra sem mexer no estoque

#### Scenario: Desconto maior que o item
- **WHEN** o desconto passa do subtotal do item
- **THEN** a folha mostra o aviso e não salva

### Requirement: Combinar o pagamento (passo 2)
O passo 2 SHALL pedir a data da venda (hoje por padrão, nunca futura) e como a cliente vai pagar: **À vista** (uma parcela com o total e a data de vencimento) ou **Dividido** (2 a 12 parcelas; o app sugere valores iguais com os centavos na última e vencimentos mês a mês a partir do 1º; cada valor e data é editável). Se a soma não bater com o total, MUST mostrar "Faltam R$ X" ou "Sobram R$ X" e bloquear. **Já recebeu a 1ª parcela agora?** SHALL pedir a forma (Pix, cartão ou dinheiro) e registrar o pagamento da 1ª parcela junto. **Concluir venda** MUST gravar tudo de uma vez e voltar; **Voltar para itens** retorna ao passo 1 sem perder nada.

#### Scenario: Dividido em 3
- **GIVEN** o total é R$ 100,00 e o 1º vencimento é 10/12
- **WHEN** ela escolhe 3 parcelas
- **THEN** aparecem R$ 33,33, R$ 33,33 e R$ 33,34 em 10/12, 10/01 e 10/02

#### Scenario: Soma diferente
- **WHEN** ela muda a 1ª parcela para R$ 30,00
- **THEN** aparece "Faltam R$ 3,33" e Concluir venda fica bloqueado

#### Scenario: Entrada paga
- **WHEN** ela marca que já recebeu a 1ª parcela no Pix e conclui
- **THEN** a 1ª parcela fica paga e a venda aparece com o pagamento

### Requirement: Gravação da venda no banco
As funções de venda MUST gravar tudo ou nada: código sequencial por consultora (#0001, #0002…), preço lido do catálogo, subtotal = preço × quantidade − desconto, totais da venda, parcelas (soma igual ao total) e o pagamento de entrada. Produto com baixa MUST consumir os lotes do mais antigo para o mais novo (data da compra, depois número do lote), gravar as saídas e o custo do item como a média ponderada dos lotes consumidos; sem saldo suficiente, MUST recusar com a mensagem do produto. Produto sem baixa usa o preço de custo do cadastro (ou zero) e serviço usa o custo de materiais (ou zero).

#### Scenario: Consome o lote mais antigo
- **GIVEN** o lote #01 (comprado antes) tem 1 un a R$ 120 e o #02 tem 3 un a R$ 150
- **WHEN** ela vende 2 un com baixa
- **THEN** sai 1 un do #01 e 1 do #02, e o custo do item é R$ 135,00

#### Scenario: Cliente de outra consultora
- **WHEN** alguém chama a função com a cliente de outra consultora
- **THEN** o banco recusa e nada é gravado

### Requirement: Detalhes da venda
O app SHALL mostrar a cliente, a data, o código e o status; a aba **Itens** com produtos e serviços (quantidade, desconto, valor) e o resumo (subtotal, descontos, total); a aba **Pagamento** com as parcelas (número "1 de 2", vencimento, valor, status). **Editar venda** MUST aparecer só enquanto nenhuma parcela tiver pagamento e reabre o passo 1 preenchido.

#### Scenario: Venda com pagamento
- **GIVEN** a 1ª parcela já foi paga
- **WHEN** ela abre os detalhes
- **THEN** o botão Editar venda não aparece

### Requirement: Editar e cancelar venda
Editar MUST devolver o estoque consumido, regravar itens e parcelas e consumir de novo, mantendo o código; MUST ser recusado se houver pagamento. **Cancelar venda** MUST pedir confirmação ("Isso apaga a venda, as parcelas e os pagamentos, e devolve os produtos ao estoque") e apagar tudo, devolvendo as unidades aos lotes.

#### Scenario: Cancelar devolve o estoque
- **GIVEN** a venda baixou 2 un do produto
- **WHEN** ela cancela e confirma
- **THEN** a venda some e o produto volta a ter as 2 un

### Requirement: Cobrar no WhatsApp
**Mais opções** SHALL oferecer **Cobrar no WhatsApp**, que abre a conversa com a cliente com a mensagem da próxima parcela em aberto (número, código da venda, valor do saldo, vencimento, a chave Pix da consultora quando cadastrada e o nome dela). Venda quitada não oferece cobrança.

#### Scenario: Mensagem com Pix
- **GIVEN** a consultora tem a chave Pix cadastrada
- **WHEN** ela cobra a parcela 2 de 2
- **THEN** a mensagem traz a parcela, o valor, o vencimento e a chave Pix

### Requirement: Isolamento das vendas
Vendas, itens, parcelas, pagamentos, saídas, as views e as funções de venda MUST respeitar o isolamento por consultora: A nunca lê, grava, edita nem cancela vendas de B, não vende produto, serviço ou para cliente de B, e o anônimo não acessa nada.

#### Scenario: Cancelar venda de outra consultora
- **WHEN** A chama o cancelamento com o id de uma venda de B
- **THEN** o banco recusa e a venda de B continua igual

#### Scenario: Anônimo
- **WHEN** o anônimo lê as views ou chama as funções de venda
- **THEN** o banco recusa
