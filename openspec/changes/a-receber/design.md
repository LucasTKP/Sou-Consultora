# Design

## Decisions

### 1. Banco (`..._a_receber.sql`)
- `registrar_pagamento(p_parcela_id uuid, p_valor numeric, p_forma text, p_data date, p_observacao text) returns uuid` — `security invoker`; trava a parcela (`for update`); saldo = valor − pagamentos; erros `SC400`; data = dia + hora atual de São Paulo (reaproveita `interno.momento_da_venda`, com mensagem própria para data futura).
- View `pagamentos_parcelas` (`security_invoker`): pagamento + `venda_id`.
- `resumo_parcelas` recriada com `nomes_itens` no fim (busca por produto); `resumo_vendas` depende dela e continua igual.

### 2. App
| Camada | Arquivo |
|---|---|
| model | `pagamento.dart` (`Pagamento`), `filtro_recebimentos.dart` (status, mês pelo vencimento, ordem), `detalhe_parcela.dart` (parcela + pagamentos + parcelas da venda + venda) |
| dto | `pagamento_dto.dart`; `resumo_parcela_dto.dart` ganha `nomes_itens` |
| service | `servico_recebimentos.dart` (parcelas, pagamentos, `registrar_pagamento`) |
| repository | `repositorio_recebimentos.dart` (cache + `Stream` das parcelas; detalhe; registrar recarrega parcelas, vendas e clientes; WhatsApp) |
- UI `ui/modules/a_receber/`: `lista/` (casca, menu), `parcela/` (detalhes + `widgets/folha_registrar_pagamento.dart`), `comprovante/` (cartão em `RepaintBoundary`, compartilhar com `share_plus`: PNG + texto curto).
- Rotas: `/a-receber` (lista), `/a-receber/parcelas/:id` e `/a-receber/parcelas/:id/comprovante[?pagamento=<id>]` — com o id, o pagamento pedido (o recém-registrado); sem ele ("Gerar recibo"), o último da parcela.
- O comprovante usa o nome e a chave Pix da consultora (`RepositorioConsultora.atual`).

## Risks / Trade-offs
- [Comprovante do "último pagamento"] → um pagamento com data retroativa não é o mais recente da parcela; por isso, logo após **Confirmar**, a rota leva o id do pagamento gravado. "Gerar recibo" (sem id) mostra o mais recente.
