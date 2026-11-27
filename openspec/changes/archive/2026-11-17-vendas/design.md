# Design

## Context
- Tabelas prontas: `vendas` (código único por consultora, `total = subtotal − total_descontos`), `itens_venda` (produto **ou** serviço; serviço nunca baixa), `parcelas` (valor > 0, número único por venda), `pagamentos_parcela` (pix/cartão/dinheiro), `saidas_estoque` (cascade pelo item), `consultoras.ultimo_codigo_venda`.
- Estoque já grava lotes; `lotes_estoque.quantidade_disponivel` é decrementado só por função.
- `resumo_clientes` já soma parcelas e pagamentos; `RotasApp.novaVendaPara` e `comprasCliente` já existem como "em construção".

## Decisions

### 1. Funções (tudo ou nada, `security invoker`, sem `consultora_id`)
- `concluir_venda(p_cliente_id uuid, p_data_venda date, p_observacoes text, p_itens jsonb, p_parcelas jsonb, p_pagamento jsonb) returns uuid`.
- `editar_venda(p_venda_id uuid, ...mesmos...) returns uuid`: recusa se houver pagamento; devolve o estoque; apaga itens e parcelas; regrava com o mesmo código.
- `cancelar_venda(p_venda_id uuid) returns void`: devolve o estoque e apaga a venda (cascade).
- Lógica comum em `interno.gravar_conteudo_venda(...)` e `interno.devolver_estoque(venda)`, num schema que o PostgREST não expõe; `usage` e `execute` só para `authenticated`.
- `p_itens`: `[{produto_id|servico_id, quantidade, desconto, baixar_estoque}]`. Preço lido de `produtos.preco_venda` / `servicos.preco_cobrado`. Custo: com baixa = média ponderada dos lotes consumidos; sem baixa = `preco_custo` (ou 0); serviço = `custo_materiais` (ou 0).
- FIFO: lotes do produto com saldo, `for update`, ordem `data_compra, numero_lote`.
- `p_parcelas`: `[{valor, data_vencimento}]`, soma igual ao total. `p_pagamento`: `{forma}` ou nulo → paga a 1ª parcela inteira na data da venda.
- `p_data_venda`: data escolhida + hora atual de São Paulo; nunca futura.
- Erros de negócio com `SC400` (mesmo padrão do estoque).

### 2. Views
| View | Uso |
|---|---|
| `resumo_vendas` | lista, detalhe e compras: venda + cliente (nome, WhatsApp), `qtd_itens`, `qtd_unidades`, `nomes_itens` (busca), `primeiro_item`, `qtd_parcelas`, `valor_pago`, `qtd_parcelas_pagas`, `tem_pagamento`, `proximo_vencimento` |
| `itens_vendas` | itens com nome, tipo, foto do produto/serviço |
| `resumo_parcelas` | parcelas com `valor_pago`, `qtd_pagamentos`, venda (código, data, total, `qtd_parcelas`) e cliente — usada também por A receber |

Status calculados no Model a partir de saldo e vencimento (hoje do aparelho), como nas outras fases.

### 3. App
- `core/model/`: `venda.dart` (resumo + `StatusVenda`), `item_venda.dart` (item do pedido e item gravado), `parcela.dart` (`StatusParcela`, saldo), `plano_parcelas.dart` (sugestão de parcelas, diferença da soma), `pedido_venda.dart` (cliente, itens, totais, validações), `filtro_vendas.dart`, `mensagem_cobranca.dart`.
- `core/service/servico_vendas.dart` e `core/repository/repositorio_vendas.dart` (cache da lista + `Stream`; depois de concluir/editar/cancelar recarrega vendas, produtos e clientes).
- `ui/modules/vendas/lista`, `ui/modules/vendas/nova` (um cubit para os 2 passos, `widgets/folha_item_venda.dart`, `widgets/passo_itens.dart`, `widgets/passo_pagamento.dart`), `ui/modules/vendas/detalhes` (abas, `widgets/folha_opcoes_venda.dart`), `ui/modules/clientes/compras`.
- Cobrar no WhatsApp: `ServicoWhatsapp` ganha mensagem opcional (`?text=`).
- Tocar na parcela abre `/a-receber/parcelas/:id` (change `a-receber`).

## Risks / Trade-offs
- [Hora da venda retroativa] → fica a hora do registro; a lista ordena pela data escolhida.
- [Mesmo item duas vezes] → bloqueado no app; para mudar, edita a linha.
