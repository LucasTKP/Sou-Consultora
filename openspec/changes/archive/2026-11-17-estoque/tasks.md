# Tasks

## 1. Banco

- [x] 1.1 Criar a migração `..._estoque.sql`: funções `lancar_estoque(date, jsonb)` e `apagar_lote(uuid)` (`security invoker`, `search_path = ''`, `execute` só para `authenticated`) e as views `lotes_produtos` e `saidas_produtos` (`security_invoker`, `select` só para `authenticated`); verificar com `supabase db reset` sem erros
- [x] 1.2 Criar `supabase/tests/09_estoque.sql`. Lançar: dois produtos de marcas diferentes geram dois lançamentos com a mesma data; numeração #01 → #02 por produto; `quantidade_disponivel = quantidade`; tudo ou nada (item inválido não grava nenhum lote); sem itens, produto repetido, data futura e validade antes da compra recusados. Apagar: lote sem saída apaga e leva o lançamento vazio junto; lote com saída é recusado com a mensagem. Views: `lotes_produtos` com fornecedor e `qtd_saidas`; `saidas_produtos` com cliente e data (usando `popular()`). Isolamento: A não lança em produto de B, não apaga lote de B, não lê lotes nem saídas de B; `anon` não lê as views nem executa as funções. Verificar com `supabase test db` passando

## 2. Model, DTO e erros

- [x] 2.1 Criar `core/model/margem.dart` e `core/model/resumo_estoque.dart`; verificar com teste unitário (R$ 219,90 × R$ 155,00 = R$ 64,90 / 29,5% / excelente; limites de 25%, 10% e 0%; prejuízo; custo médio R$ 147,45 e valor R$ 589,80 do exemplo da spec; sem lotes tudo zero)
- [x] 2.2 Criar `core/model/lote_produto.dart`, `core/model/saida_produto.dart` e `core/dto/lote_produto_dto.dart`, `core/dto/saida_produto_dto.dart`; verificar com teste unitário (situação recebido / restante / esgotado, "1 de 2 vendida", `podeApagar`, conversão de numeric e datas)
- [x] 2.3 Criar `core/model/item_lancamento.dart` (item e lançamento: totais, produto repetido, quantidade ≥ 1, custo informado, validade ≥ data da compra, data não futura, `paraGravar()`); verificar com teste unitário
- [x] 2.4 Traduzir no `core/erros/mapeador_falhas.dart` os erros de negócio das funções de estoque para `FalhaValidacao` com a mensagem do banco; verificar com teste unitário (mensagem de lote com vendas aparece; erro técnico continua com a mensagem padrão)

## 3. Service, repositório e DI

- [x] 3.1 Criar `core/service/servico_estoque.dart` (`listarLotes`, `listarSaidas`, `lancar`, `apagarLote`) e `core/repository/repositorio_estoque.dart` (recarrega o `RepositorioProdutos` depois de lançar ou apagar) e registrar no `injetor`; verificar com teste unitário usando api falsa (parâmetros da RPC sem `consultora_id`, valores em reais, falha de rede, recarga dos produtos só em sucesso)

## 4. Telas e navegação

- [x] 4.1 Criar a rota `/produtos/lancar-estoque` (antes de `/produtos/:id`) com `RotasApp.lancarEstoque`; verificar com teste de navegação (abre por cima, sem a barra)
- [x] 4.2 Criar `ui/modules/produtos/lancar_estoque/` (state, cubit, screen, `widgets/folha_item_estoque.dart`, `widgets/cartao_item_compra.dart`): data, itens, folha com margem, alterar e remover item, totais, produto repetido, salvar desabilitado sem itens, confirmação ao cancelar com itens, folha aberta com o produto vindo da rota, **Cadastrar novo produto**; verificar com testes do cubit (adicionar, repetido, remover, totais, salvar envia os itens, falha mantém os itens) e widget test (rodapé 13 un / R$ 750,00, margem "Excelente")
- [x] 4.3 Acrescentar as abas **Informações** e **Estoque N** em `ui/modules/produtos/detalhes/` (cubit carrega lotes e saídas; `widgets/aba_estoque.dart`, `widgets/cartao_lote.dart`, `widgets/cartao_saida.dart`; apagar lote com confirmação; botão do rodapé conforme a aba; recarregar depois de lançar); verificar com widget test (resumo, lotes, "Nenhuma venda ainda", lixeira só no lote sem vendas, apagar atualiza o saldo)
- [x] 4.4 Acrescentar o atalho **Lançar estoque** na lista de produtos; verificar com widget test (abre o lançamento e, na volta, a lista mostra o saldo novo)

## 5. Integração e documentação

- [x] 5.1 Acrescentar o grupo `E2E-07 Estoque` em `integration_test/app_e2e_test.dart` (no "E2E Produto": lançar 2 unidades pela aba Estoque, conferir saldo e lote relidos do banco, apagar o lote no tearDown para voltar a "Esgotado") e atualizar a tabela de cobertura e o checklist manual do README; verificar rodando só o grupo (`flutter drive --keep-app-running --dart-define=E2E_GRUPO=E2E-07`)
- [x] 5.2 Atualizar `../fluxos.md` (fornecedor do lote = marca do produto, apagar lote sem vendas, atalho na lista, regra da margem) e `../banco-de-dados.md` (`lancar_estoque` por marca, `apagar_lote`, views novas); verificar a consistência com a spec
- [x] 5.3 Rodar `flutter analyze`, `flutter test` e `supabase test db`; verificar zero problemas novos e todos os testes passando
- [x] 5.4 Aplicar a migração no remoto **só após a confirmação do dono do projeto** — aplicada em 2026-11-17 com a confirmação do dono (`db push` sem erros)
- [ ] 5.5 Percurso manual no aparelho: lançar pela lista e pelo produto, compra com duas marcas, margem, apagar lote; registrar o resultado (pode ser adiado para a rodada antes de lançar) — **adiada** para a rodada antes de lançar (checklist manual em `integration_test/README.md`)

## Resultado

- `supabase test db`: **191 testes** (28 novos em `09_estoque.sql`: um lançamento por marca, numeração #01 → #02, tudo ou nada, sem itens / repetido / data futura / validade antes da compra / custo ausente recusados, apagar lote sem e com saída, views com fornecedor, saídas e cliente, isolamento A × B × anon).
- `flutter test`: **275 testes** (novos: margem, resumo do estoque, lote, lançamento e DTOs 11, mapeador 1, service e repositório 5, telas e cubits 8, navegação 1).
- `flutter analyze`: só os 2 avisos antigos.
- Decisões de implementação:
  - erros de negócio das funções com o código próprio `SC400` e mensagem em português; o `mapeador_falhas` mostra só essas mensagens;
  - `lancar_estoque` sem tabela temporária (`jsonb_to_recordset`), travando os produtos com `for update`;
  - `BotaoFlutuanteApp` ganhou o estilo `secundario` (atalho **Lançar estoque** acima do **Novo produto**);
  - `AlternadorSegmentadoApp` passou a cortar o rótulo com reticências em tela estreita; os segmentos da aba ficaram "Entradas" e "Saídas";
  - E2E: o fornecedor fixo `fornecedorE2e` é compartilhado entre E2E-05, E2E-06 e E2E-07.
- E2E-07 executado no emulador Android contra o Supabase remoto (`flutter drive --keep-app-running`, `E2E_GRUPO=E2E-07`): **passando** — lote de 2 un relido do banco (quantidade, custo e fornecedor) e apagado no fim.
