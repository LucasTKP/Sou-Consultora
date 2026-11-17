# Design

## Context

- **Banco:**
  - `produtos` já existe, com:
    - `nome` não vazio;
    - `fornecedor_id` e `categoria_id` obrigatórios, com FKs compostas;
    - `preco_venda >= 0` e `preco_custo >= 0`;
    - `durabilidade_dias` entre 30 e 180;
    - `codigo`, `observacoes` e `foto_url`;
    - RLS forçado, 4 policies e índices em `fornecedor_id` e `categoria_id`.
  - `categorias` (tipo `produto` ou `servico`) é copiada para cada consultora no cadastro. Nada impede hoje um produto com categoria de serviço.
  - `lotes_estoque` (`quantidade_disponivel`, `validade`) existe, mas o app ainda não grava lotes. Isso fica no change `estoque`.
  - O bucket privado `fotos` existe, com policies por pasta `<auth.uid()>/`. A foto de perfil usa `<id>/perfil-<momento>.jpg`.
- **App:**
  - `ApiSupabase` tem `listar`, `buscarUm`, `inserir`, `atualizar`, `enviarArquivo`, `removerArquivos` e `urlAssinada` (uma por vez);
  - `ServicoFotoDispositivo` escolhe e recorta em 1:1;
  - `RepositorioConsultora.trocarFoto` é o modelo do fluxo "envia, grava, apaga o antigo";
  - `RepositorioFornecedores` dá a lista de marcas, e cada uma tem `ativo`;
  - `/produtos` é uma rota "em construção" dentro do shell, no item **Produtos** da barra.
- **Componentes prontos em `ui/widgets/`:**
  - `FotoQuadradaApp`, `IndicadorPassosApp`, `CampoMoedaApp`, `CampoSelecaoApp`, `CampoTextoApp`, `AreaTextoApp`, `CampoBuscaApp`;
  - `CartaoListaApp`, `CartaoApp`, `FolhaInferiorApp`;
  - estados, botões e `CabecalhoApp`.
- Motivação: `proposal.md`. Comportamento: `specs/produtos/spec.md`.

## Goals / Non-Goals

**Goals:**
- Uma leitura para a lista, já com marca, categoria e estoque, sem N+1.
- Fotos da lista com uma única chamada de URLs assinadas.
- Filtro, busca, ordem e situação do estoque como lógica pura no Model.
- Nenhum arquivo órfão no storage quando a gravação falha.

**Non-Goals:**
- Paginação e busca no servidor (uma consultora tem poucas centenas de produtos).
- Aba Estoque, lotes e lançamentos (change `estoque`).
- "Buscar produto cadastrado", cadastro de categorias, **Mais opções** e exclusão de produto.

## Decisions

### 1. View `resumo_produtos`
A view usa `security_invoker = true` e tem uma linha por produto, com:

- todas as colunas de `produtos`;
- `fornecedor_nome`, `fornecedor_ativo` e `categoria_nome`, por join;
- `qtd_disponivel` (`integer`): soma de `lotes_estoque.quantidade_disponivel`, com `coalesce(..., 0)`;
- `validade_atual` (`date`): `min(validade)` dos lotes com `quantidade_disponivel > 0`.

- **Por quê:** a lista busca, filtra e mostra marca e estoque de todos os produtos de uma vez. Detalhes usam a mesma linha. A fase de estoque vai reaproveitar a view.
- **Situação do estoque** (esgotado, baixo ≤ 2, em estoque) é calculada no Model a partir de `qtd_disponivel`, como em `banco-de-dados.md`. Assim a regra fica num lugar só do app, e a view entrega só números.
- **Alternativa descartada:** `select` com embed do PostgREST (`fornecedores(nome)`, `lotes_estoque(...)`). A soma dos lotes ficaria no app, que traria todos os lotes.

### 2. Migração `..._produtos.sql`
- Trigger `before insert or update of categoria_id` em `produtos`, `security invoker`. Ele recusa a gravação com `errcode '23514'` quando a categoria não é do tipo `produto`. A FK composta já garante que a categoria é da consultora.
- Trigger `before insert or update of codigo`, que aplica `nullif(btrim(codigo), '')`. Antes, normaliza os códigos que já existam.
- View da decisão 1, com `revoke all ... from anon, public` e `grant select ... to authenticated`.
- Índices: `lotes_produto_idx` já existe. Não precisa de índice novo.
- Não muda o CHECK de `preco_venda >= 0`. O "maior que zero" é regra do formulário (brinde de valor zero continua possível pelo banco).

### 3. Foto do produto
- Caminho `<id da consultora>/produtos/<momento em ms>.jpg` no bucket `fotos`. Ele não depende do id do produto, então a foto pode ser enviada antes do insert.
- **Salvar** no repositório:
  1. se houver foto nova, envia e guarda o caminho;
  2. grava o produto com `foto_url` (novo, trocado ou `null` se removida);
  3. se a gravação falhar, apaga a foto nova e devolve a falha;
  4. se der certo e havia foto antiga trocada ou removida, apaga a antiga. Uma falha nessa limpeza não falha o salvar.
- `foto_url` guarda o **caminho**, igual ao perfil.
- **URLs:** novo `ApiSupabase.urlsAssinadas(bucket, caminhos)`, com `createSignedUrls`, uma chamada para a lista inteira. O repositório guarda as URLs junto com o resumo. O `ResumoProduto` recebe `urlFoto` no mapper, igual a `ConsultoraDto.paraModel(urlFoto:)`.
- O formulário guarda os bytes da foto escolhida no estado até salvar. Cancelar não envia nada.

### 4. Camadas no app
| Camada | Arquivo | Responsabilidade |
|---|---|---|
| dto | `core/dto/resumo_produto_dto.dart` | linha da view + `paraModel({urlFoto})` (numeric como `int`, `double` ou `String`) |
| dto | `core/dto/categoria_dto.dart` | `id`, `nome`, `tipo` + `paraModel` |
| model | `core/model/produto.dart` | dados editáveis (`nome`, `fornecedorId`, `categoriaId`, `codigo`, `precoVendaCentavos`, `precoCustoCentavos`, `durabilidadeDias`, `observacoes`, `caminhoFoto`); validações por passo; `paraGravar()` com vazios → `null` e centavos → reais |
| model | `core/model/resumo_produto.dart` | `ResumoProduto` (produto + nomes de marca e categoria, `qtdDisponivel`, `validadeAtual`, `urlFoto`); `SituacaoEstoque` (`esgotado`, `baixo`, `emEstoque`); `combinaBusca` (nome, marca e código via `TextoBusca`); `textoEstoque` |
| model | `core/model/durabilidade.dart` | opções (30, 45, 60, 90, 120, 150 e 180 dias, mais "Sem previsão" = `null`) e o texto "60 dias (2 meses)" |
| model | `core/model/filtro_produtos.dart` | `FiltroMarcaCategoria` (todas, marca X, categoria Y), `StatusFiltroEstoque` (todos, em estoque, baixo, esgotado), `OrdemPreco` (maior, menor), contagens e a função pura `aplicar` |
| model | `core/model/categoria.dart` | `Categoria` (`id`, `nome`) |
| service | `core/service/servico_produtos.dart` | `listarResumos`, `buscarResumo(id)`, `criar`, `atualizar`, `enviarFoto`, `removerFoto`, `urlsDasFotos` via `ApiSupabase`, devolvendo `Resultado` |
| service | `core/service/servico_categorias.dart` | `listarDeProduto()` (`tipo = 'produto'`, ordem por nome) |
| repository | `core/repository/repositorio_produtos.dart` | cache + `Stream<List<ResumoProduto>>`; `salvar` com o fluxo da decisão 3; recarrega a lista depois de salvar; limpa ao encerrar a sessão; `escolherFoto` repassa ao `ServicoFotoDispositivo` |
| repository | `core/repository/repositorio_categorias.dart` | cache das categorias de produto (não mudam neste change); limpa ao encerrar a sessão |

- Os novos itens são registrados no `injetor`.
- Os erros passam por `mapeador_falhas`.
- Valores em centavos (`int`) no Model, como o `FormatadorMoeda` e o `CampoMoedaApp` já usam.

### 5. Telas (`ui/modules/produtos/`)
| Pasta | Rota | Observações |
|---|---|---|
| `lista/` | `/produtos` (shell) | `CabecalhoApp` com menu; `CampoBuscaApp` "Buscar por nome, marca ou código..."; dois `CampoSelecaoApp` lado a lado (Marca / Categoria e Status de estoque com contagens); "N produtos cadastrados" + "Preço: Maior/Menor"; `BotaoFlutuanteApp` "Novo produto" acima da barra (`MediaQuery.paddingOf(context).bottom`); `widgets/cartao_produto.dart` com `FotoQuadradaApp`, nome, preço e texto do estoque, colorido pela situação |
| `formulario/` | `/produtos/novo` e `/produtos/:id/editar` (raiz) | uma tela e um cubit com `passo` (1 ou 2) no estado; `IndicadorPassosApp`; passo 1 em `widgets/passo_dados.dart` (foto com `FolhaInferiorApp` câmera/galeria/remover, nome, marca + atalho, categoria, código); passo 2 em `widgets/passo_precos.dart` (cartão "Configurando produto", custo, venda, durabilidade, observações); a seta do topo no passo 2 volta ao passo 1 (`PopScope`); erros por campo no estado |
| `detalhes/` | `/produtos/:id` (raiz) | topo com foto, marca em maiúsculas, nome e preço; linhas de informação (campos vazios omitidos); rodapé com **Editar Produto** e, na volta, recarrega |

- **Atalho da marca:** `context.push(RotasApp.novoFornecedor)`. Na volta, o cubit recarrega as marcas do `RepositorioFornecedores`. O estado do formulário fica no cubit, então nada se perde. A marca recém-criada não é selecionada sozinha, porque o formulário de fornecedor não devolve o id. A consultora a escolhe no seletor.
- **Marcas no seletor:** só as ativas, mais a marca atual do produto, se estiver em espera.
- **Situação do estoque → cor:** o mapeamento fica no card; os detalhes não mostram estoque neste change.

### 6. Navegação
- Troca a rota "em construção" de `/produtos` pela lista.
- Cria `RotasApp.novoProduto`, `detalhesProduto(id)` e `editarProduto(id)` no navegador raiz.
- Os testes de navegação registram o repositório falso de produtos e esperam a lista real.

## Risks / Trade-offs

- [Todos os produtos "Esgotado" até o change `estoque`] → é o valor correto (não há lotes). O change `estoque` vem logo em seguida.
- [Foto órfã se o app fechar entre o envio e o insert] → raro e sem custo relevante. Fica um arquivo privado na pasta da consultora, que some ao apagar a conta.
- [URLs assinadas expiram em 1 h] → a lista pede URLs de novo a cada recarga. Se a tela ficar aberta mais de 1 h, a imagem cai para o ícone de reserva (`FotoQuadradaApp` já trata a falha).
- [Trigger de categoria] → pequeno custo por gravação. A alternativa (coluna `tipo` repetida em `produtos` com FK composta) mudaria a tabela e o modelo de dados.

## Migration Plan

1. `supabase db reset && supabase test db` local, com os testes novos passando.
2. Conferir no remoto que não há produto com categoria de serviço (`select` simples). Hoje o remoto não tem produtos.
3. Aplicar no remoto (`supabase db push`) **só com a confirmação do dono do projeto**.
4. Rollback: uma migração inversa que derruba a view e os triggers. Não há perda de dados.
