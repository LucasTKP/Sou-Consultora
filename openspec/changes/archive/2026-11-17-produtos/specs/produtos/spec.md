# Spec Delta

## Purpose

Permite à consultora manter o catálogo do que vende (foto, marca, categoria, preços e durabilidade para o lembrete de recompra) e ver, de relance, quanto tem em estoque de cada produto.

## ADDED Requirements

### Requirement: Listar produtos
O app SHALL mostrar, na tela Produtos (item da barra inferior), todos os produtos da consultora em cards com foto, nome, preço de venda e a situação do estoque, e MUST informar o total cadastrado (ex.: "42 produtos cadastrados"). Tocar no card SHALL abrir os detalhes do produto. Sem foto, o card MUST mostrar o ícone de reserva.

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

### Requirement: Situação do estoque do produto
A quantidade em estoque MUST ser a soma de `quantidade_disponivel` dos lotes do produto, calculada e nunca gravada no produto. A situação SHALL ser "Esgotado" com 0 unidade, "Baixo estoque" com 1 ou 2 unidades e "em estoque" com 3 ou mais. O card SHALL mostrar "Esgotado", "N un (Baixo estoque)" ou "N un em estoque".

#### Scenario: Sem lotes
- **GIVEN** o produto não tem lotes
- **WHEN** a lista é exibida
- **THEN** o card mostra "Esgotado"

#### Scenario: Estoque baixo
- **GIVEN** os lotes do produto somam 1 unidade disponível
- **WHEN** a lista é exibida
- **THEN** o card mostra "1 un (Baixo estoque)"

#### Scenario: Em estoque
- **GIVEN** os lotes do produto somam 4 unidades disponíveis
- **WHEN** a lista é exibida
- **THEN** o card mostra "4 un em estoque"

### Requirement: Buscar, filtrar e ordenar produtos
O app SHALL filtrar a lista pelo texto digitado, comparando com o nome, a marca e o código (sem diferenciar maiúsculas nem acentos); por uma marca ou uma categoria escolhida num único seletor; e pela situação do estoque (Todos, Em estoque, Baixo, Esgotado). O app SHALL ordenar por preço de venda, do maior para o menor (padrão) ou do menor para o maior. O seletor de estoque MUST mostrar a quantidade de cada opção.

#### Scenario: Busca pela marca sem acento
- **GIVEN** existem produtos da marca "O Boticário" e da marca "Natura"
- **WHEN** a consultora digita "boticario"
- **THEN** só aparecem os produtos de "O Boticário"

#### Scenario: Busca pelo código
- **WHEN** ela digita "bot-748"
- **THEN** aparece o produto com o código "BOT-74892"

#### Scenario: Filtro por categoria
- **WHEN** ela escolhe a categoria "Perfumaria"
- **THEN** aparecem só os produtos dessa categoria

#### Scenario: Busca sem resultado
- **WHEN** a busca não encontra nenhum produto
- **THEN** aparece "Nenhum produto encontrado", sem esconder o campo de busca

#### Scenario: Inverter a ordem
- **WHEN** ela toca no botão de ordem
- **THEN** a lista passa de "Preço: Maior" para "Preço: Menor"

### Requirement: Cadastrar produto em 2 passos
O app SHALL cadastrar o produto em 2 passos com indicador de progresso. O passo 1 SHALL pedir foto (opcional), nome, marca/fornecedor e categoria (obrigatórios) e código (opcional). O passo 2 SHALL mostrar o resumo do produto e pedir preço de custo (opcional), preço de venda (obrigatório, maior que zero), "Quanto tempo dura?" (opcional, de 30 a 180 dias, com a opção "Sem previsão") e observações (opcional). **Continuar** MUST validar o passo 1 antes de avançar; **Voltar** MUST retornar ao passo 1 mantendo tudo o que foi digitado. **Salvar produto** SHALL gravar e voltar à lista já atualizada; **Cancelar** e a seta SHALL voltar sem gravar. Se a gravação falhar, o app MUST manter os dados e mostrar o aviso.

#### Scenario: Cadastro completo
- **WHEN** a consultora informa "Kit Lily", a marca "O Boticário", a categoria "Perfumaria", o preço de venda R$ 219,90 e 60 dias, e salva
- **THEN** o produto é gravado e aparece na lista

#### Scenario: Passo 1 incompleto
- **WHEN** ela toca em **Continuar** sem escolher a marca
- **THEN** o campo da marca mostra o aviso e o passo 2 não abre

#### Scenario: Preço de venda vazio
- **WHEN** ela tenta salvar sem preço de venda
- **THEN** o campo mostra "Informe o preço de venda" e nada é gravado

#### Scenario: Sem durabilidade
- **WHEN** ela salva o produto com "Quanto tempo dura?" em "Sem previsão"
- **THEN** o produto é gravado sem durabilidade e os detalhes não mostram a linha de durabilidade

#### Scenario: Voltar ao passo 1
- **GIVEN** ela está no passo 2
- **WHEN** ela toca em **Voltar**
- **THEN** o passo 1 aparece com os dados que ela tinha preenchido

#### Scenario: Só marcas ativas
- **GIVEN** a marca "Avon" está em espera
- **WHEN** ela abre o seletor de marca de um produto novo
- **THEN** "Avon" não aparece

#### Scenario: Cadastrar marca pelo atalho
- **WHEN** ela toca no atalho ao lado da marca, cadastra o fornecedor "Eudora" e volta
- **THEN** "Eudora" aparece no seletor de marca, e o que ela tinha digitado continua na tela

#### Scenario: Falha ao salvar
- **GIVEN** não há internet
- **WHEN** ela salva
- **THEN** aparece o aviso de erro e os dados continuam preenchidos

### Requirement: Foto do produto
O passo 1 SHALL permitir escolher a foto pela câmera ou pela galeria, recortada em 1:1, e removê-la. A foto MUST ser gravada no bucket privado `fotos`, no caminho `<id da consultora>/produtos/<momento>.jpg`, e exibida por URL assinada. Ao trocar ou remover a foto de um produto salvo, o arquivo antigo MUST ser apagado depois que a gravação der certo. Se a gravação do produto falhar, o arquivo novo MUST ser apagado.

#### Scenario: Produto com foto
- **WHEN** ela escolhe uma foto da galeria e salva o produto
- **THEN** o card e os detalhes mostram a foto

#### Scenario: Trocar a foto
- **GIVEN** o produto tem foto
- **WHEN** ela edita, escolhe outra foto e salva
- **THEN** aparece a foto nova e o arquivo antigo é apagado

#### Scenario: Gravação falha depois do envio da foto
- **GIVEN** a foto foi enviada
- **WHEN** a gravação do produto falha
- **THEN** o arquivo enviado é apagado e os dados continuam na tela

### Requirement: Editar produto
O app SHALL reabrir o mesmo cadastro em 2 passos, preenchido, com o título "Editar Produto". No seletor de marca, a marca atual MUST aparecer mesmo se estiver em espera. O app MUST NOT oferecer exclusão de produto.

#### Scenario: Alterar o preço
- **GIVEN** o produto custa R$ 219,90
- **WHEN** a consultora edita o preço de venda para R$ 229,90 e salva
- **THEN** os detalhes e o card mostram R$ 229,90

#### Scenario: Marca em espera no produto já salvo
- **GIVEN** o produto é da marca "Avon", que está em espera
- **WHEN** ela abre a edição
- **THEN** o seletor mostra "Avon" escolhida

### Requirement: Detalhes do produto
O app SHALL mostrar nos detalhes: foto, marca, nome e preço de venda no topo; e na lista de informações, preço de venda, preço de custo, durabilidade estimada (ex.: "60 dias (2 meses)", com "Ideal para prever recompra"), categoria, código, validade atual e observações. A validade atual MUST ser a menor validade entre os lotes com unidades disponíveis. Campos vazios MUST ser omitidos. **Editar Produto** SHALL abrir o cadastro e, na volta, os detalhes MUST ser recarregados.

#### Scenario: Produto sem custo, código e lotes
- **GIVEN** o produto não tem preço de custo, código nem lotes
- **WHEN** a consultora abre os detalhes
- **THEN** as linhas de preço de custo, código e validade atual não aparecem

#### Scenario: Durabilidade
- **GIVEN** o produto dura 60 dias
- **WHEN** ela abre os detalhes
- **THEN** aparece "60 dias (2 meses)"

### Requirement: Integridade dos dados do produto
O banco MUST recusar produto sem nome, sem marca ou sem categoria, com preço negativo, com durabilidade fora de 30 a 180 dias, e com marca ou categoria de outra consultora. A categoria do produto MUST ser do tipo produto. Código vazio MUST ser gravado como nulo.

#### Scenario: Categoria de serviço
- **WHEN** alguém tenta gravar um produto com uma categoria do tipo serviço
- **THEN** o banco recusa a gravação

#### Scenario: Durabilidade fora da faixa
- **WHEN** alguém tenta gravar um produto com durabilidade de 200 dias
- **THEN** o banco recusa a gravação

### Requirement: Isolamento dos produtos
Produtos, o resumo de produtos e as fotos de produto MUST respeitar o isolamento por consultora: a consultora A nunca lê, cria nem altera produtos ou fotos da consultora B, a quantidade em estoque de A nunca conta lotes de B, e o usuário anônimo não acessa nada.

#### Scenario: Resumo de outra consultora
- **GIVEN** a consultora B tem produtos com lotes
- **WHEN** a consultora A consulta o resumo de produtos
- **THEN** só aparecem os produtos de A, com a quantidade dos lotes de A

#### Scenario: Alterar produto de outra consultora
- **GIVEN** A conhece o id de um produto de B
- **WHEN** A tenta alterar esse produto
- **THEN** nenhuma linha é alterada e o produto de B continua igual

#### Scenario: Marca de outra consultora
- **WHEN** A tenta gravar um produto com o `fornecedor_id` de B
- **THEN** o banco recusa

#### Scenario: Foto de outra consultora
- **WHEN** A tenta ler ou enviar um arquivo na pasta de B
- **THEN** o storage recusa

#### Scenario: Anônimo
- **WHEN** o usuário anônimo consulta produtos ou o resumo de produtos
- **THEN** nada é retornado e nada é gravado
