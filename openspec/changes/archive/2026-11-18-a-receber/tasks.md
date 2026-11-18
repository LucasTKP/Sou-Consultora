# Tasks

## 1. Banco
- [x] 1.1 Migração `..._a_receber.sql` e `supabase/tests/12_a_receber.sql` (parcial e quitação, saldo excedido, valor 0, forma inválida, data futura, view de pagamentos, `nomes_itens`, isolamento A × B × anon); verificar com `supabase test db`

## 2. Core
- [x] 2.1 Models, DTOs, service e repositório de recebimentos + DI; verificar com teste unitário (filtro por status/mês/ordem, busca por produto, validação do valor, comprovante)

## 3. Telas
- [x] 3.1 Lista, detalhes da parcela, folha de pagamento, comprovante e compartilhar; rotas; verificar com widget tests e navegação

## 4. Integração
- [x] 4.1 E2E-10 (venda E2E com 2 parcelas, pagar parcial a 1ª pela tela, conferir no banco, comprovante; cancelar a venda no fim) + README + docs
- [x] 4.2 analyze, testes, migração remota e E2E-10
