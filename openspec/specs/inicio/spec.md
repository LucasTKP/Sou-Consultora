# inicio Specification

## Purpose

Painel do dia da consultora: quanto vendeu e recebeu no mês, o que vence, quem está atrasada e quem precisa recomprar, com atalhos para cada fluxo. Não cadastra nada.

## Requirements

### Requirement: Cabeçalho do Início
O Início SHALL cumprimentar a consultora pelo primeiro nome conforme a hora do aparelho ("Bom dia" até 11h59, "Boa tarde" até 17h59, "Boa noite" depois), mostrar a foto (ou as iniciais) e abrir o menu lateral pelo botão do canto.

#### Scenario: Tarde
- **GIVEN** são 14h e a consultora se chama "Mariana Alves"
- **THEN** aparece "Boa tarde, Mariana!"

### Requirement: Números do mês
O Início SHALL mostrar o **Vendido no mês** (soma das vendas com data de venda no mês atual) e três números: **Vendas** (quantidade de vendas no mês, abre Vendas), **Recebido** (soma dos pagamentos de parcelas com data de pagamento no mês, abre A receber filtrado em Pago) e **Boletos** (soma dos boletos que vencem no mês, pagos ou não, abre A pagar).

#### Scenario: Recebido no mês
- **GIVEN** em novembro ela recebeu R$ 50,00 de uma parcela de outubro e R$ 120,00 de uma de novembro
- **THEN** Recebido mostra R$ 170,00

### Requirement: Alertas de hoje
O Início SHALL listar, com a quantidade no título, até 3 alertas de boletos não pagos vencidos, vencendo hoje ou amanhã — do mais atrasado ao mais próximo —, cada um com a marca, o valor, o selo ("VENCEU HÁ N DIAS", "VENCE HOJE", "VENCE AMANHÃ") e **Ver fatura** (abre o boleto); e, se houver parcelas atrasadas, um alerta **Vendas atrasadas** com quantas clientes e o total em atraso e **Cobrar** (abre A receber em Atrasado, todos os meses). Sem alertas, SHALL mostrar "Nada para hoje".

#### Scenario: Boleto vence amanhã
- **GIVEN** o boleto da Natura de R$ 842,50 vence amanhã e não está pago
- **THEN** aparece o alerta "VENCE AMANHÃ", "Natura", "R$ 842,50" com Ver fatura

#### Scenario: Vendas atrasadas
- **GIVEN** três clientes têm parcelas vencidas que somam R$ 280,00 em aberto
- **THEN** aparece "3 CLIENTES", "Vendas Atrasadas" e "Total R$ 280,00" com Cobrar

### Requirement: Lembrete de recompra
Para cada cliente e cada produto com duração prevista, o app SHALL considerar a última compra dela daquele produto: previsão = data da última compra + duração. SHALL mostrar "Ciclo ideal" de 7 dias antes da previsão até a previsão, e "Acabando!" depois dela, até 60 dias após a previsão; comprar o produto de novo MUST trocar a base para a compra nova. O Início SHALL mostrar os 3 mais urgentes (mais dias desde a previsão primeiro) com iniciais, nome, selo e "produto • há N dias" (desde a última compra), o ícone de conversa (abre o WhatsApp da cliente com uma mensagem pronta sobre o produto) e **Ver todos** (abre Clientes). Produto sem duração prevista MUST NOT gerar lembrete.

#### Scenario: Acabando
- **GIVEN** a Carla comprou o Lily (duração 60 dias) há 62 dias
- **THEN** o lembrete mostra "Acabando!" e "Lily • há 62 dias"

#### Scenario: Comprou de novo
- **GIVEN** a Carla comprou o Lily há 62 dias e de novo há 5 dias
- **THEN** não aparece lembrete do Lily para ela

#### Scenario: Passou da janela
- **GIVEN** a previsão do produto foi há 61 dias e ela não comprou de novo
- **THEN** o lembrete não aparece mais

### Requirement: Botão de ajuda com o suporte
O Início SHALL mostrar um botão flutuante "Ajuda" que abre o WhatsApp do suporte (+55 16 99161-4062) com uma mensagem pronta contendo o nome da consultora, a versão do app e o sistema do aparelho. O botão MUST aparecer também quando o Início falha ao carregar, e MUST NOT cobrir o último item da lista.

#### Scenario: Pedir ajuda
- **GIVEN** a consultora está no Início
- **WHEN** ela toca em "Ajuda"
- **THEN** o WhatsApp abre numa conversa com o suporte, com a mensagem "Olá! Preciso de ajuda com o app Sou Consultora." seguida do nome, da versão e de "Meu problema:"

#### Scenario: Início com erro
- **GIVEN** o Início não conseguiu carregar por falta de internet
- **THEN** o botão "Ajuda" continua visível

### Requirement: Isolamento do Início
Os números, alertas e lembretes MUST vir só dos dados da consultora logada; a view de lembretes MUST respeitar o RLS, e o anônimo não lê nada.

#### Scenario: Lembrete de outra consultora
- **WHEN** A lê os lembretes de recompra
- **THEN** não aparece nenhuma cliente de B
