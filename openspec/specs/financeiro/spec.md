# financeiro Specification

## Purpose

Mostra à consultora quanto vendeu nos últimos 12 meses e, no mês escolhido, quanto vendeu e quanto tem de boletos, com atalhos para A receber, A pagar e nova venda.

## Requirements

### Requirement: Período
O Financeiro SHALL abrir no mês atual (marcado "Mês atual") e SHALL deixar escolher outro mês/ano entre os que têm vendas ou boletos, mais os 12 meses anteriores ao atual. Todos os números da tela MUST seguir o período escolhido.

#### Scenario: Mês anterior
- **WHEN** a consultora escolhe Outubro/2026
- **THEN** o gráfico termina em Outubro/2026 e os cards mostram os números de outubro

### Requirement: Faturamento dos últimos 12 meses
O app SHALL mostrar o faturamento de cada um dos 12 meses que terminam no período escolhido, num gráfico de barras com o nome abreviado do mês, o mês escolhido em destaque com o valor abreviado em cima, e o total acumulado dos 12 meses. Faturamento do mês MUST ser a soma do total das vendas com data de venda naquele mês (à vista ou a prazo); vendas canceladas não existem mais e não contam.

#### Scenario: Virada de ano
- **GIVEN** o período é Fevereiro/2027
- **THEN** o gráfico vai de Mar/2026 a Fev/2027

#### Scenario: Mês sem vendas
- **GIVEN** não houve vendas em julho
- **THEN** a barra de julho fica vazia e julho soma R$ 0,00 no total

### Requirement: Categorias do mês
O card **A Receber** SHALL mostrar o faturamento do mês escolhido e abrir A receber. O card **A Pagar** SHALL mostrar as despesas do mês escolhido — a soma dos boletos com vencimento naquele mês, pagos ou não — e abrir A pagar.

#### Scenario: Despesas do mês
- **GIVEN** em novembro vencem um boleto pago de R$ 420,00 e um em aberto de R$ 680,00, e em dezembro um de R$ 310,00
- **WHEN** o período é Novembro
- **THEN** A Pagar mostra "Despesas no mês: R$ 1.100,00"

### Requirement: Nova venda pelo Financeiro
O botão redondo do topo SHALL abrir o lançamento de nova venda.

#### Scenario: Nova venda
- **WHEN** ela toca no botão redondo
- **THEN** abre Nova venda

### Requirement: Isolamento do financeiro
Os números MUST vir só das vendas e boletos da consultora logada: as vendas e boletos de outra consultora nunca entram nos totais, e o anônimo não vê nada.

#### Scenario: Outra consultora
- **GIVEN** a consultora B vendeu R$ 1.000,00 em novembro
- **WHEN** A abre o Financeiro de novembro
- **THEN** a venda de B não entra no faturamento de A
