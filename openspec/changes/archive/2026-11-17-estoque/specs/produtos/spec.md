# Spec Delta

## MODIFIED Requirements

### Requirement: Detalhes do produto
O app SHALL mostrar nos detalhes: foto, marca, nome e preço de venda no topo, e duas abas: **Informações** e **Estoque**. A aba **Estoque** MUST mostrar no rótulo a quantidade disponível e é descrita na capability `estoque`. A aba **Informações** SHALL mostrar preço de venda, preço de custo, durabilidade estimada (ex.: "60 dias (2 meses)", com "Ideal para prever recompra"), categoria, código, validade atual e observações. A validade atual MUST ser a menor validade entre os lotes com unidades disponíveis. Campos vazios MUST ser omitidos. **Editar Produto** SHALL abrir o cadastro e, na volta, os detalhes MUST ser recarregados.

#### Scenario: Produto sem custo, código e lotes
- **GIVEN** o produto não tem preço de custo, código nem lotes
- **WHEN** a consultora abre os detalhes
- **THEN** as linhas de preço de custo, código e validade atual não aparecem

#### Scenario: Durabilidade
- **GIVEN** o produto dura 60 dias
- **WHEN** ela abre os detalhes
- **THEN** aparece "60 dias (2 meses)"

#### Scenario: Trocar para a aba Estoque
- **GIVEN** o produto tem 4 unidades disponíveis
- **WHEN** ela toca na aba "Estoque 4"
- **THEN** aparece o resumo do estoque com as entradas e as saídas

### Requirement: Listar produtos
O app SHALL mostrar, na tela Produtos (item da barra inferior), todos os produtos da consultora em cards com foto, nome, preço de venda e a situação do estoque, e MUST informar o total cadastrado (ex.: "42 produtos cadastrados"). Tocar no card SHALL abrir os detalhes do produto. Sem foto, o card MUST mostrar o ícone de reserva. A tela SHALL oferecer **Novo produto** e o atalho **Lançar estoque**, que abre o lançamento vazio e volta à lista atualizada.

#### Scenario: Lista com produtos
- **GIVEN** a consultora tem 3 produtos
- **WHEN** ela abre Produtos
- **THEN** aparecem 3 cards e o texto "3 produtos cadastrados"

#### Scenario: Lista vazia
- **GIVEN** a consultora não tem produtos
- **WHEN** ela abre Produtos
- **THEN** aparece o estado vazio com o convite para cadastrar o primeiro produto

#### Scenario: Falha de rede
- **GIVEN** não há internet
- **WHEN** ela abre Produtos
- **THEN** aparece o erro com **Tentar novamente**, e tocar nele refaz a busca

#### Scenario: Lançar estoque pela lista
- **WHEN** ela toca em **Lançar estoque**, lança 2 unidades de um produto esgotado e salva
- **THEN** ela volta à lista e o card mostra "2 un (Baixo estoque)"
