# Tasks

## 1. Banco
- [x] 1.1 Migração `..._inicio.sql` (view `lembretes_recompra`) e `supabase/tests/14_inicio.sql` (última compra, sem duração e serviço fora, venda cancelada, A × B × anon); verificar com `supabase test db`

## 2. Core
- [x] 2.1 DTO e model do lembrete (previsão, situação, janela), `ResumoInicio`, pagamentos de todos os meses, service/repository do Início, mensagem de recompra + DI; verificar com teste unitário

## 3. Telas
- [x] 3.1 Tela Início (cabeçalho e números, alertas, lembretes, atalhos) e rota; widget tests
- [x] 3.2 A receber com status inicial (`?status=`) e selo de atrasadas no menu lateral; widget tests

## 4. Integração
- [x] 4.1 E2E-13 (venda temporária a prazo atrasada e boleto vencendo amanhã: Início mostra os números e alertas iguais ao banco; Cobrar agora abre A receber em Atrasado; limpa no fim) + README + docs
- [x] 4.2 analyze, testes, migração remota e E2E-13
