# servicos Specification

## Purpose

Permite à consultora manter o catálogo dos serviços que oferece, com preço, custo de materiais e o retorno de cada atendimento, para usá-los nas vendas.

## Requirements

### Requirement: Listar serviços
O app SHALL mostrar, na tela Serviços (aberta pelo menu lateral), os serviços da consultora em cards com foto (ou ícone de reserva), nome, categoria e preço cobrado, e MUST informar o total ("5 serviços cadastrados"). Tocar no card SHALL abrir os detalhes.

#### Scenario: Lista vazia
- **GIVEN** a consultora não tem serviços
- **WHEN** ela abre Serviços
- **THEN** aparece o convite para cadastrar o primeiro serviço

#### Scenario: Falha de rede
- **GIVEN** não há internet
- **WHEN** ela abre Serviços
- **THEN** aparece o erro com **Tentar novamente**

### Requirement: Buscar, filtrar e ordenar serviços
O app SHALL filtrar pelo nome digitado (sem diferenciar maiúsculas nem acentos) e pela categoria escolhida (com a quantidade de cada opção), e SHALL ordenar por nome de A-Z ou Z-A.

#### Scenario: Filtro por categoria
- **WHEN** ela escolhe a categoria "Unhas"
- **THEN** aparecem só os serviços de Unhas

#### Scenario: Busca sem resultado
- **WHEN** a busca não encontra nenhum serviço
- **THEN** aparece "Nenhum serviço encontrado"

### Requirement: Cadastrar e editar serviço
O app SHALL cadastrar o serviço numa tela com foto (opcional), nome e categoria (obrigatórios), preço cobrado (obrigatório, maior que zero), custo de materiais, duração estimada e observações (opcionais). O retorno estimado (preço − custo, em R$ e % do preço) MUST ser mostrado enquanto ela preenche. **Salvar serviço** SHALL gravar e voltar; a seta SHALL voltar sem gravar; falha ao salvar MUST manter os dados com o aviso. A edição reabre a mesma tela preenchida. O app MUST NOT oferecer exclusão.

#### Scenario: Retorno estimado
- **WHEN** ela informa preço R$ 150,00 e custo R$ 30,00
- **THEN** aparece "R$ 120,00 (80%)"

#### Scenario: Campos obrigatórios
- **WHEN** ela salva sem nome, sem categoria ou sem preço
- **THEN** cada campo mostra o aviso e nada é gravado

#### Scenario: Só categorias de serviço
- **WHEN** ela abre o seletor de categoria
- **THEN** aparecem só as categorias do tipo serviço

### Requirement: Detalhes do serviço
O app SHALL mostrar foto (ou ícone), categoria, nome, preço cobrado, custo de materiais, retorno estimado (R$ e "% do valor cobrado"), duração (ex.: "1h 30min (90 min)") e observações. Campos vazios MUST ser omitidos. **Editar serviço** SHALL abrir o cadastro e, na volta, os detalhes MUST ser recarregados.

#### Scenario: Sem custo
- **GIVEN** o serviço não tem custo de materiais
- **WHEN** ela abre os detalhes
- **THEN** o retorno estimado é o preço inteiro (100%)

### Requirement: Integridade dos dados do serviço
O banco MUST recusar serviço sem nome, sem categoria, com categoria do tipo produto ou de outra consultora, com preço ou custo negativo e com duração ≤ 0.

#### Scenario: Categoria de produto
- **WHEN** alguém grava um serviço com uma categoria do tipo produto
- **THEN** o banco recusa

### Requirement: Isolamento dos serviços
Serviços, o resumo de serviços e as fotos de serviço MUST respeitar o isolamento por consultora: A nunca lê, cria nem altera serviços de B, e o anônimo não acessa nada.

#### Scenario: Ler serviço de outra consultora
- **WHEN** A consulta o resumo de serviços
- **THEN** só aparecem os serviços de A

#### Scenario: Alterar serviço de outra consultora
- **WHEN** A tenta alterar um serviço de B
- **THEN** nenhuma linha é alterada

#### Scenario: Anônimo
- **WHEN** o anônimo consulta serviços ou o resumo
- **THEN** o banco recusa
