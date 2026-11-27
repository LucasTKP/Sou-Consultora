# Proposal

## Why

O Início é a primeira tela depois do login e ainda é "em construção". A consultora precisa abrir o app e ver, sem procurar, quanto vendeu, o que entrou, o que vence, quem está atrasada e quem já deve estar precisando recomprar.

## What Changes

- **Início** (item central da barra): cumprimento pela hora ("Bom dia/Boa tarde/Boa noite, Mariana!") com a foto; **Vendido no mês**; três números que abrem listas — **Vendas** (pedidos no mês → Vendas), **Recebido** (pagamentos de parcelas no mês → A receber em "Pago") e **Boletos** (boletos que vencem no mês, pagos ou não, como no Financeiro → A pagar).
- **Alertas de hoje** (com a quantidade): um alerta por boleto não pago vencido, vencendo hoje ou amanhã ("VENCEU HÁ 3 DIAS", "VENCE HOJE", "VENCE AMANHÃ"), até 3, com **Ver fatura** (abre o boleto); e um alerta de **Vendas atrasadas** (quantas clientes e o total) com **Cobrar agora** (abre A receber em "Atrasado", todos os meses).
- **Lembrete de recompra**: clientes cujo produto (com duração prevista) está no fim — "Ciclo ideal" nos 7 dias antes de acabar, "Acabando!" depois, até ela comprar o produto de novo ou 60 dias depois de acabar; os 3 mais urgentes, com o ícone de conversa (WhatsApp com mensagem pronta) e **Ver todos** (abre Clientes).
- **A receber**: a lista passa a aceitar um status inicial vindo do Início (Atrasado ou Pago), já em "Todos os meses".
- **Menu lateral**: selo em **A Receber / Cobranças** com quantas parcelas estão atrasadas.
- **Banco:** view `lembretes_recompra` (última compra de cada produto com duração prevista por cliente, `security_invoker`).

## Capabilities

### New Capabilities
- `inicio`: painel do dia — números do mês, alertas de boletos e cobranças e lembrete de recompra, com atalhos para os módulos.

### Modified Capabilities
- `a-receber`: a lista abre com o status escolhido no Início (Atrasado ou Pago).
- `navegacao-do-app`: o menu lateral mostra o selo de cobranças atrasadas em A Receber.

## Impact

- **Banco:** `..._inicio.sql` (view `lembretes_recompra`) e `supabase/tests/14_inicio.sql` (última compra, produto sem duração fica de fora, recompra substitui a anterior, isolamento A × B × anon).
- **App:** core (lembrete: dto, model com a situação, service/repository; pagamentos do período em `ServicoRecebimentos`; `ResumoInicio` com os números e alertas); `ui/modules/inicio/` (tela única); rota `/inicio`; `/a-receber?status=`; selo no menu (casca); mensagem de recompra no WhatsApp.
- **Testes:** unitários, widget e E2E-13.
