# Proposal

## Why

Venda, estoque e o lembrete de recompra dependem de produtos cadastrados: no banco, `itens_venda.produto_id` e `lotes_estoque.produto_id` apontam para `produtos`. Hoje Produtos é uma tela "em construção", embora seja o primeiro item da barra inferior. Os fornecedores (marcas) já existem, e todo produto precisa de uma marca. Por isso o catálogo é o próximo passo. O estoque (lotes, lançamentos e a aba Estoque) fica no change seguinte, `estoque`.

## What Changes

- **Lista de produtos** (item **Produtos** da barra inferior):
  - busca por nome, marca ou código, sem diferenciar maiúsculas nem acentos;
  - filtro único de marca ou categoria;
  - filtro de estoque: todos, em estoque, baixo e esgotado;
  - ordem por preço de venda, do maior para o menor ou o contrário;
  - total cadastrado ("42 produtos cadastrados");
  - o card mostra foto, nome, preço de venda e a quantidade em estoque ("4 un em estoque", "1 un (Baixo estoque)", "Esgotado");
  - o botão **Novo produto** abre o cadastro.
- **Novo produto, em 2 passos:**
  - **Passo 1, dados do produto:**
    - foto opcional (câmera ou galeria, recortada em 1:1);
    - nome, marca/fornecedor e categoria, obrigatórios;
    - código ou referência, opcional;
    - o atalho ao lado da marca abre **Novo fornecedor** e, na volta, a lista de marcas é recarregada;
    - **Continuar** vai ao passo 2; **Cancelar** volta à lista.
  - **Passo 2, preços e durabilidade:**
    - resumo do produto em configuração;
    - preço de custo, opcional;
    - preço de venda, obrigatório;
    - "Quanto tempo dura?" (30 a 180 dias), opcional, para o lembrete de recompra (sem ela, o produto não gera lembrete);
    - observações ou fragrância, opcional;
    - **Salvar produto** grava e volta à lista; **Voltar** retorna ao passo 1 sem perder nada.
- **Editar produto:** o mesmo cadastro em 2 passos, já preenchido, com o título "Editar Produto". Também dá para trocar ou remover a foto.
- **Detalhes do produto:**
  - foto, marca, nome e preço de venda;
  - preço de venda, preço de custo, durabilidade estimada ("60 dias (2 meses)" e "Ideal para prever recompra"), categoria, código, validade atual e observações;
  - campos vazios são omitidos;
  - **Editar Produto** abre o cadastro e, na volta, os detalhes são recarregados.
- **Banco:**
  - view de resumo por produto com o nome da marca e da categoria, a quantidade disponível e a validade atual, calculadas dos lotes (nada gravado);
  - CHECK de durabilidade e preços já existe; o código ganha `btrim` e vazio vira nulo.
- **Fora do escopo:**
  - aba **Estoque**, lançar estoque e lotes (change `estoque`). Até lá, todo produto aparece como "Esgotado", porque ainda não há lotes;
  - "Buscar produto cadastrado" no passo 1 (o `fluxos.md` diz que fica para depois);
  - o atalho da categoria e o cadastro de categorias (usa as categorias padrão copiadas no cadastro da consultora);
  - **Mais opções** e apagar produto.

## Capabilities

### New Capabilities
- `produtos`: catálogo de produtos da consultora (cadastro em 2 passos com foto, consulta, filtros, edição e detalhes), com a quantidade em estoque e a validade calculadas dos lotes.

### Modified Capabilities
- (nenhuma). As regras de isolamento, integridade e storage que já existem (`isolamento-de-dados`, `modelo-de-dados`) passam a valer também para a view nova e para as fotos de produto, sem mudar os requisitos delas.

## Impact

- **Banco:**
  - nova migração `..._produtos.sql` com a view `resumo_produtos` (`security_invoker`) e a limpeza do código;
  - testes pgTAP dos números da view com lotes de teste e de isolamento A × B × anon.
- **App:**
  - `core`:
    - `dto`, `model`, `service` e `repository` de produto;
    - categorias (só leitura, tipo produto);
    - `ApiSupabase` ganha URLs assinadas em lote, para as fotos da lista;
    - `ServicoFotoDispositivo`, que já existe, é reaproveitado;
  - `ui/modules/produtos/` com `lista`, `formulario` (2 passos) e `detalhes`;
  - rotas `/produtos/novo`, `/produtos/:id` e `/produtos/:id/editar`, abertas por cima da barra;
  - fotos em `fotos/<id da consultora>/produtos/<momento>.jpg`, no bucket privado que já existe.
- **Dependências:** nenhuma nova.
- **Testes:**
  - unitários e de widget das camadas novas;
  - grupo E2E-06 no `integration_test/`, que roda só antes de lançar versão.
