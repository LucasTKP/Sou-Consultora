# Design

## Context

- **Banco (tabelas já existem, com RLS forçado, 4 policies e FKs compostas):**
  - `lancamentos_estoque` (`fornecedor_id` e `data_compra` obrigatórios): uma compra de uma marca;
  - `lotes_estoque`:
    - `numero_lote` > 0 e único por produto;
    - `quantidade` > 0;
    - `quantidade_disponivel` entre 0 e `quantidade`;
    - `custo_unitario` ≥ 0 e `validade` opcional;
  - `saidas_estoque` (lote × item de venda), com FK para o lote **sem cascade**, então um lote com saída não pode ser apagado;
  - `itens_venda`/`vendas`/`clientes` existem, mas o app ainda não grava vendas;
  - `resumo_produtos` já soma `qtd_disponivel` e a `validade_atual`.
- **App:**
  - `RepositorioProdutos` (cache + `Stream`) alimenta a lista e os detalhes;
  - a tela de detalhes do produto hoje tem só as informações;
  - `ApiSupabase.rpc` e `listar(onde:)` já existem.
- **Componentes prontos em `ui/widgets/`:**
  - `AlternadorSegmentadoApp` (Entradas × Saídas), `SeletorQuantidadeApp`, `CampoMoedaApp`, `CampoDataApp`, `CampoSelecaoApp` (com busca);
  - `FolhaInferiorApp`, `DialogoConfirmacaoApp`, `SeloStatusApp`, `CartaoApp`, `BotaoFlutuanteApp`.
- Motivação: `proposal.md`. Comportamento: `specs/estoque/spec.md` e `specs/produtos/spec.md`.

## Goals / Non-Goals

**Goals:**
- Lançamento atômico: ou todos os lotes da compra são gravados, ou nenhum.
- Numeração de lote sem duplicar, mesmo com dois lançamentos ao mesmo tempo.
- Custo médio, valor em estoque, margem e situação dos lotes como lógica pura no Model.
- Leituras da aba Estoque em poucas chamadas, sem N+1.

**Non-Goals:**
- Editar lote, boleto da compra, abrir a venda a partir da saída.
- Consumo FIFO (é da fase de Vendas, na função `concluir_venda`).

## Decisions

### 1. Função `lancar_estoque(p_data_compra date, p_itens jsonb) returns integer`
- `security invoker`, `set search_path = ''`, sem `consultora_id` como parâmetro. `execute` revogado de `public`/`anon` e concedido a `authenticated`.
- `p_itens` é uma lista de `{produto_id, quantidade, custo_unitario, validade}`. Ela é validada no início:
  - pelo menos um item;
  - nenhum produto repetido;
  - `p_data_compra` não pode ser futura (`(now() at time zone 'America/Sao_Paulo')::date`);
  - validade, quando houver, não pode ser anterior à data da compra.
  - Erros saem com `errcode 'SC400'` e mensagem em português.
- **Produtos:** busca os produtos com `select ... for update` (RLS ativo), o que trava cada produto contra lançamentos concorrentes. Se algum id não voltar (não existe ou é de outra consultora), recusa com `SC400` e a mensagem "Produto não encontrado.".
- **Gravação:** agrupa os itens por `produtos.fornecedor_id` e cria um `lancamentos_estoque` por marca, com a mesma data. Cada lote recebe:
  - `numero_lote` = `coalesce(max(numero_lote), 0) + 1` do produto, calculado com o produto já travado;
  - `quantidade_disponivel = quantidade`.
- Devolve o total de lotes gravados.
- **Por quê:** é a forma de deixar a gravação tudo ou nada e a numeração segura. Agrupar por marca mantém o schema (fornecedor por lançamento) e atende à decisão de que cada lote é da marca do produto.
- **Alternativa descartada:** coluna `fornecedor_id` em `lotes_estoque`. Mudaria a tabela e o modelo de dados sem ganho, porque o lançamento já carrega a marca.

### 2. Função `apagar_lote(p_lote_id uuid) returns void`
- `security invoker`, mesmas permissões da decisão 1.
- `delete` do lote (o RLS esconde o lote de outra consultora, então nada é apagado e a função recusa com `SC400` e "Lote não encontrado.").
- Lote com saída: a FK de `saidas_estoque` recusa (`23503`), e a função converte isso em `SC400` com "Este lote já teve vendas e não pode ser apagado.".
- Se o lançamento ficar sem lotes, ele também é apagado.
- A numeração não é reaproveitada: o próximo lote continua do maior número existente + 1.

### 3. Views
| View | Linha | Colunas |
|---|---|---|
| `lotes_produtos` | um lote | `id`, `produto_id`, `numero_lote`, `quantidade`, `quantidade_disponivel`, `custo_unitario`, `validade`, `data_compra`, `fornecedor_nome`, `qtd_saidas` (unidades que saíram dele), `created_at` |
| `saidas_produtos` | um item de venda com baixa | `item_venda_id`, `produto_id`, `venda_id`, `data_venda`, `cliente_nome`, `quantidade`, `subtotal` |

- Ambas com `security_invoker = true`, `revoke all ... from anon, public` e `grant select ... to authenticated`.
- **Pode apagar** = `quantidade_disponivel = quantidade` **e** `qtd_saidas = 0`, calculado no Model.
- `saidas_produtos` lê `itens_venda` com `produto_id` preenchido e `baixar_estoque = true`, junto com `vendas` e `clientes`. Até a fase de Vendas ela fica vazia. Na fase de Vendas não precisa mudar.

### 4. Camadas no app
| Camada | Arquivo | Responsabilidade |
|---|---|---|
| dto | `core/dto/lote_produto_dto.dart` e `core/dto/saida_produto_dto.dart` | linhas das views + `paraModel` |
| model | `core/model/lote_produto.dart` | `LoteProduto` (situação: recebido / restante / esgotado, `totalPago`, `vendidas`, `podeApagar`, rótulo "#02") |
| model | `core/model/saida_produto.dart` | `SaidaProduto` |
| model | `core/model/resumo_estoque.dart` | a partir da lista de lotes: `saldo`, `custoMedio` (ponderado pelo disponível, arredondado ao centavo), `valorEmEstoque`, `prontaEntrega` |
| model | `core/model/margem.dart` | `Margem.calcular(precoVenda, custo)` → valor, porcentagem e `FaixaMargem` (`excelente` ≥ 25%, `boa` ≥ 10%, `baixa` ≥ 0%, `prejuizo` < 0) |
| model | `core/model/item_lancamento.dart` | item da compra (produto, quantidade, custo, validade), `total`, validações (quantidade ≥ 1, custo informado, validade ≥ data da compra), `paraGravar()`; `LancamentoEstoque` com data, itens, totais e a regra de produto repetido |
| service | `core/service/servico_estoque.dart` | `listarLotes(produtoId)`, `listarSaidas(produtoId)`, `lancar(data, itens)` (RPC), `apagarLote(id)` (RPC) |
| repository | `core/repository/repositorio_estoque.dart` | expõe essas operações e, depois de lançar ou apagar, recarrega o `RepositorioProdutos` (saldo e situação da lista e dos detalhes) |

- As funções sinalizam erro de negócio com o código próprio `SC400` (data futura, item inválido, produto repetido, produto ou lote não encontrado, lote com vendas), sempre com mensagem em português para a consultora. O `mapeador_falhas` traduz só `SC400` para `FalhaValidacao` com a mensagem do banco; os demais erros continuam com a mensagem padrão, sem expor texto técnico.
- Valores em centavos no Model, como em Produtos.

### 5. Telas
| Pasta | Rota | Observações |
|---|---|---|
| `produtos/detalhes/` | `/produtos/:id` | ganha as abas **Informações** e **Estoque N** (`TabBar` com o mesmo cubit). A aba Estoque usa `widgets/aba_estoque.dart` com o cartão de resumo, `AlternadorSegmentadoApp` Entradas × Saídas, `widgets/cartao_lote.dart` (com a lixeira só quando `podeApagar`) e `widgets/cartao_saida.dart`. O botão do rodapé muda com a aba: **Editar Produto** ou **Lançar Estoque** |
| `produtos/lancar_estoque/` | `/produtos/lancar-estoque?produto=<id>` (raiz) | state, cubit, screen; `widgets/folha_item_estoque.dart` (produto com busca, preço e estoque atual, `SeletorQuantidadeApp`, `CampoMoedaApp`, `CampoDataApp`, cartão de margem); `widgets/cartao_item_compra.dart`; rodapé com os totais. Com `produto`, a folha abre sozinha ao entrar, com o produto escolhido. **Salvar lançamento** fecha devolvendo `true` |
| `produtos/lista/` | `/produtos` | ganha o atalho **Lançar estoque** (botão secundário acima do "Novo produto") |

- O cubit de detalhes carrega o produto, os lotes e as saídas em paralelo. Depois de lançar ou apagar, recarrega os três.
- **Cadastrar novo produto**, no lançamento, faz `push` do cadastro. Na volta, a lista de produtos da folha vem do `RepositorioProdutos` já recarregado.
- A margem só aparece quando há custo informado.

### 6. Navegação
- `RotasApp.lancarEstoque({String? produtoId})`, no navegador raiz. A rota fica antes de `/produtos/:id` para não ser lida como um id.

## Risks / Trade-offs

- [Um lançamento vira vários por marca] → na tela não aparece diferença, porque a consultora vê os lotes por produto. Em relatórios futuros de compras, "uma compra" pode aparecer dividida por marca. É aceitável, porque cada parte é mesmo de um fornecedor.
- [Trava por produto (`for update`)] → dois lançamentos do mesmo produto ao mesmo tempo esperam um pelo outro por milissegundos. É o comportamento desejado.
- [Mensagens do banco na tela] → só as mensagens das funções de estoque, escritas em português para a consultora. Os outros erros continuam com a mensagem padrão.
- [Custo médio arredondado] → arredondado ao centavo só na exibição. O valor em estoque é a soma exata.

## Migration Plan

1. `supabase db reset && supabase test db` local, com os testes novos passando.
2. Aplicar no remoto (`supabase db push`) **só com a confirmação do dono do projeto**. Não há dados a converter: o remoto só tem lotes de teste, se tiver.
3. Rollback: uma migração inversa que derruba as funções e as views. Não há perda de dados.
