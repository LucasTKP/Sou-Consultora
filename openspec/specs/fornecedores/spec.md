# fornecedores Specification

## Purpose

Permite à consultora manter as marcas de quem compra (contato, telefone, ramo e observações do ciclo), ver de relance quais estão ativas, em espera ou com boleto vencendo hoje, e deixar uma marca de lado sem perder o histórico.

## Requirements

### Requirement: Listar fornecedores
O app SHALL mostrar, na tela principal de Fornecedores (aberta pelo menu lateral), todos os fornecedores da consultora em cards com iniciais, nome, a quantidade de boletos em aberto ("Nenhum boleto em aberto", "1 boleto em aberto", "2 boletos em aberto") e o selo de status, e MUST informar o total cadastrado (ex.: "5 fornecedores"). Tocar no card SHALL abrir os detalhes do fornecedor.

#### Scenario: Lista com fornecedores
- **GIVEN** a consultora tem 3 fornecedores
- **WHEN** ela abre Fornecedores
- **THEN** aparecem 3 cards e o texto "3 fornecedores"

#### Scenario: Lista vazia
- **GIVEN** a consultora não tem fornecedores
- **WHEN** ela abre Fornecedores
- **THEN** aparece o estado vazio com o convite para cadastrar o primeiro fornecedor

#### Scenario: Falha de rede
- **GIVEN** não há internet
- **WHEN** ela abre Fornecedores
- **THEN** aparece o erro com **Tentar novamente**, e tocar nele refaz a busca

### Requirement: Status do fornecedor
O app SHALL mostrar um único selo por fornecedor, nesta prioridade: "Vence hoje" (tem boleto não pago com vencimento hoje), "Em espera" (marcado como em espera) e "Ativo" (nenhum dos anteriores). Boleto "em aberto" MUST ser todo boleto sem data de pagamento, vencido ou não; "atrasado" é o boleto em aberto com vencimento antes de hoje. "Hoje" MUST ser o dia em `America/Sao_Paulo`. Os números MUST ser calculados a partir dos boletos e nunca gravados.

#### Scenario: Boleto vencendo hoje
- **GIVEN** o fornecedor tem um boleto não pago que vence hoje
- **WHEN** a lista é exibida
- **THEN** o card mostra o selo "Vence hoje"

#### Scenario: Vence hoje tem prioridade sobre em espera
- **GIVEN** o fornecedor está em espera e tem boleto não pago vencendo hoje
- **WHEN** a lista é exibida
- **THEN** o card mostra "Vence hoje"

#### Scenario: Em espera
- **GIVEN** o fornecedor está em espera e não tem boleto vencendo hoje
- **WHEN** a lista é exibida
- **THEN** o card mostra "Em espera"

#### Scenario: Sem boletos
- **GIVEN** o fornecedor está ativo e não tem boletos
- **WHEN** a lista é exibida
- **THEN** o card mostra "Ativo" e "Nenhum boleto em aberto"

### Requirement: Buscar, filtrar e ordenar fornecedores
O app SHALL filtrar a lista pelo nome digitado (sem diferenciar maiúsculas nem acentos) e pelo status escolhido (Todos, Ativos, Em espera, Vence hoje), e SHALL ordenar por nome de A-Z ou Z-A. O filtro "Vence hoje" MUST incluir todo fornecedor com boleto em aberto vencendo hoje, mesmo em espera. "Ativos" MUST incluir todo fornecedor que não está em espera. O seletor de status MUST mostrar a quantidade de cada opção.

#### Scenario: Busca sem acento
- **GIVEN** existe o fornecedor "O Boticário"
- **WHEN** a consultora digita "boticario"
- **THEN** só "O Boticário" aparece

#### Scenario: Filtro em espera
- **WHEN** ela escolhe "Em espera"
- **THEN** aparecem só os fornecedores marcados como em espera

#### Scenario: Busca sem resultado
- **WHEN** a busca não encontra nenhum fornecedor
- **THEN** aparece "Nenhum fornecedor encontrado", sem esconder o campo de busca

#### Scenario: Inverter a ordem
- **WHEN** ela toca em ordenar
- **THEN** a lista passa de A-Z para Z-A

### Requirement: Cadastrar fornecedor
O app SHALL cadastrar o fornecedor em uma tela com nome (obrigatório), ramo, contato, telefone/WhatsApp e observações (opcionais). O telefone MUST ser digitado com máscara e gravado só com dígitos (DDD + 8 ou 9). **Salvar** SHALL gravar e voltar à lista já atualizada; **Cancelar** e a seta SHALL voltar sem gravar. Se a gravação falhar, o app MUST manter o que foi digitado e mostrar o aviso.

#### Scenario: Cadastro mínimo
- **WHEN** a consultora informa só o nome "Natura" e salva
- **THEN** o fornecedor é gravado como ativo e aparece na lista

#### Scenario: Nome vazio
- **WHEN** ela tenta salvar sem nome
- **THEN** o campo mostra "Informe o nome do fornecedor" e nada é gravado

#### Scenario: Telefone incompleto
- **WHEN** ela digita "(11) 9876" e salva
- **THEN** o campo mostra que o telefone está incompleto e nada é gravado

#### Scenario: Nome repetido
- **GIVEN** já existe o fornecedor "Natura"
- **WHEN** ela cadastra outro com o nome "natura"
- **THEN** aparece o aviso de que já existe um fornecedor com esse nome e os dados digitados continuam na tela

#### Scenario: Falha ao salvar
- **GIVEN** não há internet
- **WHEN** ela salva
- **THEN** aparece o aviso de erro e os campos continuam preenchidos

### Requirement: Editar fornecedor e colocar em espera
O app SHALL reabrir o mesmo formulário preenchido em **Editar fornecedor**, com o interruptor **Em espera**, que só aparece na edição. O app MUST NOT oferecer exclusão de fornecedor.

#### Scenario: Colocar em espera
- **GIVEN** o fornecedor "Mary Kay" está ativo
- **WHEN** a consultora edita, liga **Em espera** e salva
- **THEN** os detalhes e o card mostram "Em espera"

#### Scenario: Reativar
- **GIVEN** o fornecedor está em espera
- **WHEN** ela desliga **Em espera** e salva
- **THEN** o fornecedor volta a "Ativo"

#### Scenario: Sem exclusão
- **WHEN** ela abre os detalhes de um fornecedor
- **THEN** não existe botão para excluir

### Requirement: Detalhes do fornecedor
O app SHALL mostrar nos detalhes: iniciais, nome, ramo (quando houver), selo de status e "Parceiro desde" com mês e ano do cadastro; o resumo dos boletos com valor e quantidade em aberto, pagos e atrasados; contato, telefone com o botão **WhatsApp** e observações. Campos vazios MUST ser omitidos. **Ver em A pagar** SHALL abrir A pagar mostrando só os boletos daquele fornecedor; na volta, os detalhes MUST ser recarregados (o resumo reflete boletos pagos, lançados ou excluídos lá). **Editar fornecedor** SHALL abrir o formulário e, na volta, os detalhes MUST ser recarregados.

#### Scenario: Fornecedor sem boletos
- **GIVEN** o fornecedor não tem boletos
- **WHEN** a consultora abre os detalhes
- **THEN** o resumo mostra R$ 0,00 e "0 boletos" em aberto, pagos e atrasados

#### Scenario: Sem telefone
- **GIVEN** o fornecedor não tem telefone
- **WHEN** ela abre os detalhes
- **THEN** a linha do telefone e o botão **WhatsApp** não aparecem

#### Scenario: Abrir WhatsApp do fornecedor
- **GIVEN** o fornecedor tem o telefone 11987654321
- **WHEN** ela toca em **WhatsApp**
- **THEN** o app abre a conversa com +55 11 98765-4321 e, se não conseguir, mostra um aviso

#### Scenario: Parceiro desde
- **GIVEN** o fornecedor foi cadastrado em março de 2023
- **WHEN** ela abre os detalhes
- **THEN** aparece "Parceiro desde mar/2023"

#### Scenario: Ver em A pagar
- **GIVEN** a Natura tem 2 boletos e a Eudora 1
- **WHEN** ela toca em **Ver em A pagar** nos detalhes da Natura
- **THEN** A pagar mostra só os 2 boletos da Natura

### Requirement: Integridade dos dados do fornecedor
O banco MUST recusar nome vazio, telefone que não tenha só 10 ou 11 dígitos e nome repetido para a mesma consultora (sem diferenciar maiúsculas nem espaços nas pontas). Consultoras diferentes MAY ter fornecedores com o mesmo nome.

#### Scenario: Telefone com máscara
- **WHEN** alguém tenta gravar o fornecedor com telefone "(11) 98765-4321"
- **THEN** o banco recusa a gravação

#### Scenario: Nome repetido na mesma consultora
- **GIVEN** a consultora tem o fornecedor "Natura"
- **WHEN** alguém tenta gravar outro fornecedor " NATURA " para ela
- **THEN** o banco recusa a gravação

#### Scenario: Mesmo nome em consultoras diferentes
- **GIVEN** a consultora B tem o fornecedor "Natura"
- **WHEN** a consultora A cadastra "Natura"
- **THEN** a gravação é aceita

### Requirement: Isolamento dos fornecedores
Fornecedores e o resumo de fornecedores MUST respeitar o isolamento por consultora: a consultora A nunca lê, cria nem altera fornecedores da consultora B, os números do resumo de A nunca contam boletos de B, e o usuário anônimo não acessa nada.

#### Scenario: Resumo de outra consultora
- **GIVEN** a consultora B tem fornecedores com boletos em aberto
- **WHEN** a consultora A consulta o resumo de fornecedores
- **THEN** só aparecem os fornecedores de A, com os números dos boletos de A

#### Scenario: Alterar fornecedor de outra consultora
- **GIVEN** A conhece o id de um fornecedor de B
- **WHEN** A tenta alterar esse fornecedor
- **THEN** nenhuma linha é alterada e o fornecedor de B continua igual

#### Scenario: Gravar como outra consultora
- **WHEN** A tenta inserir um fornecedor com o `consultora_id` de B
- **THEN** o banco recusa

#### Scenario: Anônimo
- **WHEN** o usuário anônimo consulta fornecedores ou o resumo de fornecedores
- **THEN** nada é retornado e nada é gravado
