# Tasks

## 1. Banco
- [x] 1.1 Migração `..._a_pagar.sql` (view `resumo_boletos`, trigger da data de pagamento) e `supabase/tests/13_a_pagar.sql` (view, data hoje/amanhã/null, isolamento A × B × anon, FK com fornecedor de B, Storage na pasta de B); verificar com `supabase test db`

## 2. Core
- [x] 2.1 `excluir` na api; DTO, models (situação, textos do card, validações), filtro, service (com comprovante) e repositório de boletos + DI; verificar com teste unitário (situação, filtro por status/mês/fornecedor, busca por marca/observação, contagens, validações, tamanho do comprovante)

## 3. Telas
- [x] 3.1 Lista (com filtro por fornecedor) e rota na casca; widget tests
- [x] 3.2 Novo/editar boleto em 2 passos; widget tests
- [x] 3.3 Detalhes, pagar (folha com data), desfazer, opções, comprovante (câmera, galeria, PDF; ver) e excluir; `file_picker`; widget tests
- [x] 3.4 Fornecedores: Ver em A pagar abre a lista filtrada e recarrega na volta; widget test

## 4. Integração
- [x] 4.1 E2E-11 (lança boleto do "E2E Fornecedor" pela tela, confere no banco, paga com a data de hoje, desfaz, exclui) + README + docs
- [x] 4.2 analyze, testes, migração remota e E2E-11
