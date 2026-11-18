# Proposal

## Why

Vender é o coração do app: a consultora precisa registrar o pedido (produtos e serviços), definir como a cliente vai pagar (à vista ou parcelas livres) e acompanhar se foi pago. Clientes, produtos, estoque e serviços já existem; o banco já tem `vendas`, `itens_venda`, `parcelas`, `pagamentos_parcela` e `saidas_estoque`, mas nenhuma função grava uma venda. O dono do projeto pediu Vendas junto com Serviços e A receber.

## What Changes

- **Lista de vendas** (barra → Vendas): busca por cliente, produto ou código; filtro de status (em aberto, atrasada, quitada) com contagens; filtro de mês/ano (padrão: mês atual; opção "Todos os meses"); ordem por data (mais recentes/antigas); card com iniciais, cliente, quando ("Hoje • 14:30", "Ontem • 16:45", "12/11 • 11:20"), itens, total e status; **Nova venda**.
- **Nova venda — passo 1 (itens):** cliente (com busca e atalho para cadastrar), **Adicionar produto ou serviço**, linhas editáveis/removíveis com quantidade, desconto e valor; rodapé com subtotal, descontos e total; **Avançar** / **Cancelar** (confirma se já houver itens).
- **Folha do item:** Produto | Serviço; item do catálogo (com busca); quantidade; desconto em R$ (opcional, até o subtotal); para produto, **Baixar do estoque** (ligado por padrão) com o saldo: ligado, a quantidade não passa do saldo ("Estoque insuficiente: X un disponíveis"); desligado, entra como encomenda. Preço sempre o do catálogo.
- **Nova venda — passo 2 (pagamento):** data da venda (hoje, editável, nunca futura); **À vista** (1 parcela com vencimento) ou **Dividido** (2 a 12 parcelas sugeridas iguais, centavos na última, mês a mês; cada valor e data editável; "Faltam R$ X"/"Sobram R$ X" bloqueia); **Já recebeu a 1ª parcela agora?** com a forma (Pix, cartão, dinheiro); observação; resumo; **Concluir venda** grava tudo de uma vez.
- **Detalhes da venda:** cliente, data, código (#0012) e status; abas **Itens** e **Pagamento** (parcelas com Pago/Parcial/A receber/Atrasada; tocar abre o detalhe da parcela — fase A receber); **Editar venda** só sem pagamentos; **Mais opções**: Cobrar no WhatsApp (próxima parcela em aberto, mensagem com chave Pix), Gerar recibo (do último pagamento — fase A receber) e Cancelar venda (confirmação; apaga tudo e devolve o estoque).
- **Clientes:** **Nova venda** já com a cliente; **Compras da cliente** (total gasto, atrasado/pendente/pago, filtro de status, busca de produto, compras que abrem a venda, **Nova Venda**).
- **Banco:** funções `concluir_venda`, `editar_venda` e `cancelar_venda` (tudo ou nada; preço lido do catálogo; código sequencial; consumo FIFO dos lotes com custo médio; validação de soma das parcelas); views `resumo_vendas`, `itens_vendas` e `resumo_parcelas`.

## Capabilities

### New Capabilities
- `vendas`: registrar, consultar, editar e cancelar vendas de produtos e serviços, com parcelas, baixa de estoque e cobrança.

### Modified Capabilities
- `clientes`: Nova venda e Compras da cliente deixam de ser "em construção".

## Impact

- **Banco:** `..._vendas.sql` (schema `interno` para a lógica compartilhada das funções, 3 funções, 3 views) e `supabase/tests/11_vendas.sql`.
- **App:** core de vendas (dto, model, service, repository); `ui/modules/vendas/` (lista, nova — 2 passos + folha de item —, detalhes); `ui/modules/clientes/compras/`; rotas `/vendas/nova`, `/vendas/:id`, `/vendas/:id/editar`, `/clientes/:id/compras`.
- **Testes:** unitários, widget e E2E-09.
