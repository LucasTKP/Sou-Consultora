# Proposal

## Why

Com vendas, recebimentos e boletos no app, a consultora ainda não tem onde ver, de relance, quanto vendeu no ano e quanto entra e sai no mês. O Financeiro (item da barra) hoje é uma tela "em construção".

## What Changes

- **Financeiro** (item da barra): escolhe o **período** (mês/ano; padrão mês atual, marcado "Mês atual").
- **Faturamento – Últimos 12 meses**: total acumulado e gráfico de barras dos 12 meses que terminam no mês escolhido (o mês escolhido em destaque, com o valor abreviado em cima, ex.: "5.4k"). Faturamento = soma das **vendas** do mês, pela data da venda (à vista ou a prazo).
- **Categorias do Mês**: **A Receber** com o faturamento do mês escolhido (abre A receber) e **A Pagar** com as despesas do mês = soma dos **boletos que vencem no mês**, pagos ou não (abre A pagar).
- Botão redondo no topo: **Nova venda**.
- **Fora desta fase** (decisão do dono): lucro do mês e valor parado em estoque.

## Capabilities

### New Capabilities
- `financeiro`: visão do mês e dos últimos 12 meses (faturamento pelas vendas, despesas pelos boletos) com atalhos para A receber, A pagar e nova venda.

### Modified Capabilities
- (nenhuma)

## Impact

- **Banco:** nenhuma migração. Os números vêm das views que já existem (`resumo_vendas`, `resumo_boletos`), sob o RLS de cada consultora.
- **App:** `core/model/resumo_financeiro.dart` (cálculo puro dos meses e totais); `ui/modules/financeiro/` (tela única, na casca); rota `/financeiro` deixa de ser "em construção"; widget de gráfico de barras em `ui/widgets/graficos/`.
- **Testes:** unitários (meses, totais, virada de ano, venda/boleto de outro mês), widget e E2E-12.
