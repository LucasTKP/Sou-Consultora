# Tasks

## 1. Banco
- [x] 1.1 Migração `..._vendas.sql` (schema `interno`, funções `concluir_venda`, `editar_venda`, `cancelar_venda`, views `resumo_vendas`, `itens_vendas`, `resumo_parcelas`) e `supabase/tests/11_vendas.sql` (código sequencial, preço do catálogo, totais, FIFO com custo médio, sem estoque recusa, encomenda sem baixa, serviço, parcelas que não somam, entrada paga, editar devolve e reconsome e recusa com pagamento, cancelar devolve, isolamento A × B × anon); verificar com `supabase test db`

## 2. Core
- [x] 2.1 Models (venda, item, parcela, plano de parcelas, pedido, filtro, mensagem de cobrança) e DTOs; verificar com teste unitário (status, sugestão 33,33/33,33/33,34, diferença da soma, desconto, estoque insuficiente, mensagem com Pix)
- [x] 2.2 `servico_vendas.dart`, `repositorio_vendas.dart`, WhatsApp com mensagem, DI; verificar com teste unitário

## 3. Telas
- [x] 3.1 Lista de vendas e rotas; verificar com widget test
- [x] 3.2 Nova/editar venda (passo 1, folha de item, passo 2); verificar com testes do cubit e widget
- [x] 3.3 Detalhes (abas, editar só sem pagamento, mais opções: cobrar, recibo, cancelar); verificar com widget test
- [x] 3.4 Clientes: Nova venda e Compras da cliente; verificar com widget test

## 4. Integração
- [x] 4.1 E2E-09 (venda à vista do "E2E Produto" para "E2E Cliente" com encomenda, detalhes, cancelar no fim) + README + `../fluxos.md` + `../banco-de-dados.md`
- [x] 4.2 analyze, testes, migração remota e E2E-09

## Resultado

- `supabase test db`: 235 testes (32 novos em `11_vendas.sql`). `flutter test`: 305. `flutter analyze`: só os 2 avisos antigos.
- Migração aplicada no remoto (autorizado pelo dono para esta fase); E2E-04 e E2E-09 passando no emulador Android (a venda E2E é cancelada no fim).
- Decisões de implementação:
  - lógica comum das funções no schema `interno` (`gravar_conteudo_venda`, `baixar_estoque`, `devolver_estoque`, `momento_da_venda`), fora do PostgREST;
  - status de venda/parcela calculado no app a partir de `saldo`, `valor_atrasado` e vencimento;
  - `ServicoWhatsapp` aceita mensagem (`?text=`); a mensagem de cobrança fica em `ui/formatadores/mensagem_cobranca.dart`;
  - tocar numa parcela e "Gerar recibo" abrem as rotas de A receber (`/a-receber/parcelas/:id` e `/comprovante`), entregues no change `a-receber`;
  - teste de FIFO fixa a data do lote antigo (o `popular()` usa a data UTC).
- Percurso manual adiado para a rodada antes de lançar (checklist do README).
