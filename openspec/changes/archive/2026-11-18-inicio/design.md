# Design

## Context

- **Banco (já existe):** `resumo_vendas` (`data_venda`, `total`), `resumo_parcelas` (saldo, vencimento, cliente), `resumo_boletos` e `pagamentos_parcelas` (`data_pagamento`), todas `security_invoker` e testadas; `produtos.durabilidade_dias` (30 a 180, opcional) e `itens_venda` (produto e venda). Não há como saber a **última compra de cada produto por cliente** sem juntar itens, vendas e produtos.
- **App:** `RepositorioVendas`, `RepositorioRecebimentos` e `RepositorioBoletos` carregam as listas com cache e `Stream`; `ServicoRecebimentos` só lista pagamentos por venda; `CascaPrincipalCubit` alimenta o menu lateral (nome, foto, versão); `ServicoWhatsapp` e `MensagemCobranca` existem; `/inicio` é rota "em construção" (rota inicial após o login).
- Motivação: `proposal.md`. Comportamento: `specs/`.

## Goals / Non-Goals

**Goals:**
- Números, alertas e situação do lembrete como lógica pura no Model (`ResumoInicio`, `LembreteRecompra`), testável sem Flutter.
- O Início e o selo do menu atualizam sozinhos quando vendas, parcelas ou boletos mudam.

**Non-Goals:**
- Notificações push e lembretes fora do app.
- Lista própria de "todos os lembretes" (Ver todos abre Clientes, como no fluxo).
- Lembrete por serviço (`servicos.retorno_dias` segue sem uso).

## Decisions

### 1. Banco (`..._inicio.sql`)
- View `lembretes_recompra` (`security_invoker`): uma linha por (cliente, produto com `durabilidade_dias`) com a **última** compra — `distinct on (v.cliente_id, iv.produto_id) ... order by v.data_venda desc` sobre `itens_venda` × `vendas` × `produtos` × `clientes` (joins pelas FKs compostas). Colunas: `cliente_id`, `cliente_nome`, `cliente_whatsapp`, `produto_id`, `produto_nome`, `durabilidade_dias`, `ultima_compra` (dia em São Paulo). Itens de serviço ficam de fora (`produto_id` nulo). `revoke` de `anon, public`; `grant select` a `authenticated`.
- A janela (7 dias antes, 60 depois) e a ordem ficam no app: a view só entrega a última compra.
- Teste `14_inicio.sql`: última compra vence a anterior, produto sem duração e serviço ficam de fora, venda cancelada some, A × B × anon.

### 2. App
| Camada | Arquivo |
|---|---|
| dto | `lembrete_recompra_dto.dart` |
| model | `lembrete_recompra.dart` (`previsao`, `situacao(hoje)` → ciclo ideal / acabando / fora, dias desde a compra), `resumo_inicio.dart` (`ResumoInicio.calcular(vendas, pagamentos, parcelas, boletos, lembretes, hoje)` → vendido, quantidade, recebido, boletos do mês, alertas de boletos, atrasadas, 3 lembretes) |
| service | `servico_inicio.dart` (view de lembretes); `ServicoRecebimentos.listarTodosPagamentos()` |
| repository | `repositorio_inicio.dart` (lembretes + pagamentos; WhatsApp de recompra) |
| formatador | `mensagem_recompra.dart` ("Oi, Carla! Tudo bem? 😊 Já faz 62 dias que você levou o Lily…") |
- UI `ui/modules/inicio/` (tela única): `inicio_state.dart`, `inicio_cubit.dart`, `inicio_screen.dart`, `widgets/` (cabeçalho com os números, alertas, lembretes). O cubit carrega as cinco fontes em paralelo e assina os `Stream` de vendas, parcelas e boletos.
- A receber: `AReceberListaScreen(statusInicial:)`; rota `/a-receber?status=atrasado|pago` (na casca). Com status inicial, o mês começa em "Todos os meses".
- Menu: `CascaPrincipalCubit` assina `RepositorioRecebimentos.mudancas` e guarda `qtdAtrasadas`; `MenuLateral` mostra o selo em A Receber quando > 0.
- Atalhos: Vendas → `go(/vendas)`; Recebido → `go(/a-receber?status=pago)`; Boletos → `go(/a-pagar)`; Ver fatura → `push(detalhesBoleto)`; Cobrar agora → `go(/a-receber?status=atrasado)`; Ver todos → `go(/clientes)`.

## Risks / Trade-offs
- [Cinco leituras ao abrir] O Início é a primeira tela → as leituras vão em paralelo e as listas ficam em cache para os outros módulos.
- [Soma no app] Pagamentos de todos os meses → aceitável no volume de uma consultora (mesmo raciocínio do Financeiro).
