# Tasks

## 1. Banco

- [x] 1.1 Criar a migração `..._produtos.sql`: trigger de categoria do tipo produto (`23514`), trigger de `btrim` do código (vazio → nulo, normalizando os existentes) e a view `resumo_produtos` (`security_invoker`, `select` só para `authenticated`) com `fornecedor_nome`, `fornecedor_ativo`, `categoria_nome`, `qtd_disponivel` e `validade_atual`; verificar com `supabase db reset` sem erros
- [x] 1.2 Criar `supabase/tests/08_produtos.sql`. Integridade: categoria de serviço recusada, durabilidade 200 recusada, preço negativo recusado, código "  " vira nulo. View: produto sem lotes com 0 e validade nula; lotes de 3 e 1 somam 4; validade atual ignora lote sem saldo. Isolamento: A não lê o resumo nem os produtos de B, update de A no produto de B não altera nada, produto de A com `fornecedor_id` de B recusado, insert com `consultora_id` de B recusado, a quantidade de A não conta lotes de B, A não lê nem envia arquivo em `fotos/<B>/produtos/`, `anon` não lê a tabela nem a view. Verificar com `supabase test db` passando

## 2. Model e DTO

- [x] 2.1 Criar `core/model/categoria.dart` e `core/dto/categoria_dto.dart`; verificar com teste unitário de conversão
- [x] 2.2 Criar `core/model/durabilidade.dart` (opções 30 a 180 + "Sem previsão" e o texto "60 dias (2 meses)", "45 dias") e `core/model/produto.dart` (validação do passo 1: nome, marca, categoria; do passo 2: preço de venda > 0, durabilidade opcional; `paraGravar()` com vazios → `null` e centavos → reais); verificar com teste unitário
- [x] 2.3 Criar `core/model/resumo_produto.dart` (situação do estoque 0 / 1-2 / 3+, textos "Esgotado", "1 un (Baixo estoque)", "4 un em estoque", busca por nome, marca e código sem acento) e `core/model/filtro_produtos.dart` (marca ou categoria, estoque com contagens, ordem por preço maior/menor); verificar com teste unitário cobrindo cada situação, "boticario" → marca "O Boticário", "bot-748" → código "BOT-74892" e as duas ordens
- [x] 2.4 Criar `core/dto/resumo_produto_dto.dart` com `fromJson` e `paraModel({urlFoto})` (numeric como `int`, `double` ou `String`; validade nula); verificar com teste unitário de conversão

## 3. API, service, repositório e DI

- [x] 3.1 Acrescentar `urlsAssinadas(bucket, caminhos)` em `core/api/api_supabase.dart` (`createSignedUrls`, lista vazia sem chamada); verificar com `flutter analyze`
- [x] 3.2 Criar `core/service/servico_categorias.dart` e `core/service/servico_produtos.dart` (`listarResumos`, `buscarResumo`, `criar`, `atualizar`, `enviarFoto` em `<id>/produtos/<momento>.jpg`, `removerFoto`, `urlsDasFotos`); verificar com teste unitário usando api falsa (sucesso, falha de rede, dados sem `consultora_id`/`id`/`created_at`, caminho da foto na pasta da consultora)
- [x] 3.3 Criar `core/repository/repositorio_categorias.dart` e `core/repository/repositorio_produtos.dart` (cache, `Stream`, URLs das fotos numa chamada, `salvar` com o fluxo envia → grava → apaga antiga / apaga nova se falhar, recarregar após salvar, limpar ao encerrar a sessão, `escolherFoto`) e registrar no `injetor`; verificar com teste unitário (salvar com foto nova apaga a antiga; falha ao gravar apaga a foto enviada e mantém o cache; remover foto grava `null` e apaga o arquivo; sessão encerrada limpa o cache)

## 4. Navegação

- [x] 4.1 Trocar a rota "em construção" de `/produtos` pela lista e criar `/produtos/novo`, `/produtos/:id` e `/produtos/:id/editar` no navegador raiz (constantes em `RotasApp`); verificar com os testes de navegação atualizados (lista com barra, detalhe sem barra, voltar)

## 5. Telas

- [x] 5.1 Criar `ui/modules/produtos/lista/` (state, cubit, screen, `widgets/cartao_produto.dart`): busca, filtro de marca/categoria, filtro de estoque com contagens, ordem por preço, contador "N produtos cadastrados", textos de estoque, vazio, sem resultado, erro e o botão "Novo produto" acima da barra; verificar com testes do cubit (filtrar, buscar, ordenar, stream atualiza) e widget test (textos de estoque, vazio, erro com tentar novamente)
- [x] 5.2 Criar `ui/modules/produtos/formulario/` (state, cubit, screen, `widgets/passo_dados.dart`, `widgets/passo_precos.dart`): 2 passos com `IndicadorPassosApp`, foto (câmera, galeria, remover), marcas ativas + a atual, atalho para Novo fornecedor recarregando as marcas, voltar ao passo 1 sem perder dados, título "Novo" × "Editar", aviso de erro mantendo os dados; verificar com testes do cubit (Continuar bloqueado sem marca, preço vazio não grava, voltar mantém os dados, editar envia os campos alterados, falha mostra o aviso) e widget test (passo 1 → passo 2 → voltar)
- [x] 5.3 Criar `ui/modules/produtos/detalhes/` (state, cubit, screen): topo com foto, marca, nome e preço; linhas de informação com campos vazios omitidos, durabilidade "60 dias (2 meses)" e "Ideal para prever recompra", validade atual; **Editar Produto** e recarregar na volta; sem botão de excluir; verificar com widget test (produto sem custo, código e lotes esconde as linhas)

## 6. Integração e documentação

- [x] 6.1 Acrescentar o grupo `E2E-06 Produtos` em `integration_test/app_e2e_test.dart` (cadastrar sem foto, com nome único prefixado `E2E` e a marca "E2E Fornecedor", ver na lista como "Esgotado", buscar, abrir detalhes, editar o preço e restaurar no tearDown) e atualizar a tabela de cobertura e o checklist manual do README (foto pela câmera e pela galeria, trocar e remover a foto, atalho da marca); verificar com `flutter analyze` (o E2E só roda antes de lançar)
- [x] 6.2 Atualizar `../fluxos.md` (durabilidade opcional, marcas ativas no seletor, estoque calculado dos lotes, sem exclusão) e `../banco-de-dados.md` (`resumo_produtos`, categoria do tipo produto, código sem espaços, caminho da foto); verificar a consistência com a spec
- [x] 6.3 Rodar `flutter analyze` e `flutter test`; verificar zero problemas novos e todos os testes passando
- [x] 6.4 Aplicar a migração no remoto **só após a confirmação do dono do projeto** (conferir antes produtos com categoria de serviço) — aplicada em 2026-11-17 com a confirmação do dono (`db push` sem erros)
- [ ] 6.5 Percurso manual no aparelho: cadastrar com foto da galeria e da câmera, atalho da marca, buscar, filtrar, ordenar, abrir detalhes, editar e trocar a foto; registrar o resultado (pode ser adiado para a rodada de conferência antes de lançar) — **adiada** para a rodada antes de lançar (item no checklist manual de `integration_test/README.md`)

## Resultado

- `supabase test db`: **163 testes** (20 novos em `08_produtos.sql`: categoria de serviço, durabilidade e preço fora da faixa, código em branco vira nulo, estoque e validade da view com lotes de teste, isolamento A × B × anon, inclusive foto na pasta de B).
- `flutter test`: **251 testes** (novos: models/DTO 12, service 7, repositório 7, telas e cubits 16; teste de navegação de Produtos pela barra).
- `flutter analyze`: só os 2 avisos antigos (`tipografia_app.dart` e `perfil_test.dart`).
- Decisões de implementação:
  - durabilidade **opcional** ("Sem previsão" = nulo), por decisão do dono do projeto;
  - um trigger só (`preparar_produto`) faz a limpeza do código e confere o tipo da categoria;
  - `ApiSupabase.listar` ganhou filtro por igualdade (`onde`) e `urlsAssinadas` (`createSignedUrlsResult`, uma chamada para a lista inteira);
  - a folha de foto saiu do Perfil para `ui/widgets/dialog/folha_foto_app.dart` (`FolhaFotoApp`), usada por Perfil e Produtos;
  - `MudancaFoto` (`ManterFoto`, `TrocarFoto`, `RemoverFoto`) no repositório define o que fazer com a foto ao salvar;
  - preço de custo zero no formulário conta como "não informado".
- E2E-06 executado no emulador Android (`flutter drive`, `E2E_GRUPO=E2E-06`) contra o Supabase remoto: **2 cenários passando** (cadastro em 2 passos + busca pelo código + detalhes; edição do preço relida do banco e restaurada). Rodado de novo junto com o E2E-05 usando `--keep-app-running`: os dois passando.
