# Proposal

## Why

Com as vendas gravando parcelas, a consultora precisa ver o que as clientes ainda devem, parcela por parcela, registrar o que recebe (inclusive pagamentos parciais) e mandar o comprovante. Vendas já leva a esta fase (tocar numa parcela, "Gerar recibo"). O dono do projeto pediu A receber junto com Vendas.

## What Changes

- **Recebimentos** (menu → A receber): parcelas do mês (pelo vencimento; padrão mês atual, opção "Todos os meses"); busca por cliente ou produto; status (Todos, A receber, Atrasado, Vence hoje, Pago, com contagens); ordem (vencimento mais próximo/distante, maior/menor valor); card com iniciais, cliente, "Parcela 2/2" ou "Parcela única", selo ("Atrasado (15/10)", "Vence hoje", "Venc. 25/10", "Pago em 18/10") e valor.
- **Detalhes da parcela**: saldo em aberto com barra pago × resta, valor da parcela, vencimento ("Venceu em 15/10 • há 18 dias" / "Vence em 25/10"); cliente com telefone e **Cobrar**; pagamentos desta parcela; a venda (código, data, unidades, total — abre a venda) e as parcelas dela (tocar abre a outra; "Você está aqui"); **Pagar** (com saldo) e **Mais opções** (cobrar, gerar recibo, cancelar venda).
- **Registrar pagamento** (folha): valor (preenchido com o saldo, editável para parcial, nunca maior que o saldo), forma (Pix, cartão, dinheiro), data (hoje, nunca futura) e observação; **Confirmar** registra e abre o comprovante.
- **Comprovante**: pagamento confirmado, valor pago, data e hora, consultora e chave Pix, cliente, forma, "Parcela 2 de 2 • Quitada/Parcial", a venda com as parcelas e o saldo restante; **Compartilhar** envia a imagem do comprovante com uma descrição curta.
- **Banco:** função `registrar_pagamento`, view `pagamentos_parcelas`, e `resumo_parcelas` ganha `nomes_itens` (busca por produto).

## Capabilities

### New Capabilities
- `a-receber`: acompanhar parcelas a receber, registrar pagamentos (inclusive parciais) e gerar/compartilhar comprovante.

### Modified Capabilities
- (nenhuma)

## Impact

- **Banco:** `..._a_receber.sql` e `supabase/tests/12_a_receber.sql`.
- **App:** core (pagamento: dto, model, service, repository de recebimentos); `ui/modules/a_receber/` (lista, parcela com a folha de pagamento, comprovante); rotas; dependência `share_plus` (compartilhar a imagem).
- **Testes:** unitários, widget e E2E-10.
