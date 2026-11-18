# Design

## Context

- **Banco (já existe):** `resumo_vendas` (`data_venda`, `total`) e `resumo_boletos` (`data_vencimento`, `valor`), ambas `security_invoker` e cobertas pelos testes de isolamento de `11_vendas.sql` e `13_a_pagar.sql`.
- **App:** `RepositorioVendas` e `RepositorioBoletos` já carregam as listas inteiras (com cache e `Stream`); `MesAno` e `FormatadorData.mesAnoAbreviado` existem; `/financeiro` é rota "em construção" na casca (item da barra).
- Motivação: `proposal.md`. Comportamento: `specs/financeiro/spec.md`.

## Goals / Non-Goals

**Goals:**
- Cálculo dos 12 meses, totais e categorias como lógica pura no Model, testável sem Flutter.
- A tela atualiza sozinha quando vendas ou boletos mudam (assina os `Stream` dos dois repositórios).

**Non-Goals:**
- Lucro do mês e valor parado em estoque (decisão do dono: ficam para depois).
- Agregação no servidor e relatórios exportáveis.

## Decisions

### 1. Sem migração
Uma consultora tem centenas de vendas e boletos por ano; somar no app a partir das listas que Vendas e A pagar já carregam evita uma view nova só para isso. Se o volume crescer, uma view `faturamento_mensal` (`security_invoker`) substitui a soma sem mudar a tela. Sem migração, não há teste SQL novo: o isolamento vem das views existentes, já testadas.

### 2. App
| Camada | Arquivo |
|---|---|
| model | `resumo_financeiro.dart` (`ResumoFinanceiro.calcular(vendas, boletos, periodo)` → 12 `FaturamentoMes`, total acumulado, faturamento e despesas do mês; `ResumoFinanceiro.periodos(...)`) |
| formatador | `formatador_moeda.dart` ganha `abreviado` ("5.4k", "980", "1.2M") |
| widget | `ui/widgets/graficos/grafico_barras_app.dart` (barras simples, sem pacote de gráfico; uma barra em destaque com o rótulo em cima) |
| tela | `ui/modules/financeiro/` (tela única: `financeiro_state.dart`, `financeiro_cubit.dart`, `financeiro_screen.dart`, `widgets/`) |
- Cubit carrega `RepositorioVendas.carregar()` e `RepositorioBoletos.carregar()` em paralelo e assina `mudancas` dos dois.
- Cards: **A Receber** → `context.go(RotasApp.aReceber)`; **A Pagar** → `context.go(RotasApp.aPagar)`; botão redondo do topo → `push(RotasApp.novaVenda)`.

## Risks / Trade-offs
- [Soma no app] Carrega todas as vendas e boletos → aceitável no volume de uma consultora; caminho de troca por view descrito acima.
- [Mês atual] "Hoje" vem do relógio do aparelho (como em A receber e A pagar).
