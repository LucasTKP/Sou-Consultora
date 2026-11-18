# clientes Specification

## Purpose
Permite à consultora manter a carteira de clientes (contato, aniversário, preferências e endereço de entrega) e ver, de relance, quem está em dia, quem deve e quem faz aniversário.

## Requirements

### Requirement: Listar clientes
O app SHALL mostrar, na tela principal de Clientes, todas as clientes da consultora em cards com iniciais, nome, uma linha de apoio e o selo de situação, e MUST informar o total cadastrado (ex.: "28 clientes cadastrados"). Tocar no card SHALL abrir os detalhes da cliente.

#### Scenario: Lista com clientes
- **GIVEN** a consultora tem 3 clientes
- **WHEN** ela abre Clientes
- **THEN** aparecem 3 cards e o texto "3 clientes cadastrados"

#### Scenario: Lista vazia
- **GIVEN** a consultora não tem clientes
- **WHEN** ela abre Clientes
- **THEN** aparece o estado vazio com o convite para cadastrar a primeira cliente

#### Scenario: Falha de rede
- **GIVEN** não há internet
- **WHEN** ela abre Clientes
- **THEN** aparece o erro com **Tentar novamente**, e tocar nele refaz a busca

### Requirement: Situação da cliente
O app SHALL mostrar um único selo por cliente, na ordem de prioridade: "Deve R$ X" (há parcela vencida não paga; X = valor atrasado), "Vence hoje R$ X" (há parcela vencendo hoje não paga), "Aniversário" (o aniversário cai no mês atual) e "Em dia" (nenhum dos anteriores). Os valores MUST ser calculados a partir das parcelas e pagamentos e nunca gravados.

#### Scenario: Cliente com parcela atrasada
- **GIVEN** a cliente tem R$ 120,00 em parcela vencida e não paga
- **WHEN** a lista é exibida
- **THEN** o card mostra o selo "Deve R$ 120,00"

#### Scenario: Atraso tem prioridade sobre aniversário
- **GIVEN** a cliente faz aniversário neste mês e tem parcela atrasada
- **WHEN** a lista é exibida
- **THEN** o card mostra "Deve", e não "Aniversário"

#### Scenario: Sem vendas
- **GIVEN** a cliente não tem vendas e não faz aniversário no mês
- **WHEN** a lista é exibida
- **THEN** o card mostra "Em dia"

### Requirement: Buscar, filtrar e ordenar
O app SHALL filtrar a lista pelo nome digitado (sem diferenciar maiúsculas nem acentos), pelo status escolhido (Todos, Em dia, Com saldo, Aniversariantes) e SHALL ordenar por nome de A-Z ou Z-A. "Com saldo" MUST incluir toda cliente com saldo devedor maior que zero, vencido ou não. O seletor de status MUST mostrar a quantidade de cada opção.

#### Scenario: Busca sem acento
- **GIVEN** existe a cliente "Patrícia Ribeiro"
- **WHEN** a consultora digita "patricia"
- **THEN** só "Patrícia Ribeiro" aparece

#### Scenario: Filtro aniversariantes
- **WHEN** ela escolhe "Aniversariantes"
- **THEN** aparecem só as clientes com aniversário no mês atual

#### Scenario: Busca sem resultado
- **WHEN** a busca não encontra ninguém
- **THEN** aparece "Nenhuma cliente encontrada", sem esconder o campo de busca

#### Scenario: Inverter a ordem
- **WHEN** ela toca em "Nome: A-Z"
- **THEN** a lista passa a Z-A e o rótulo muda para "Nome: Z-A"

### Requirement: Cadastrar cliente em dois passos
O app SHALL cadastrar a cliente em dois passos. Passo 1: nome completo e WhatsApp com DDD (obrigatórios), data de nascimento e observações (opcionais). Passo 2 (opcional): CEP, rua, número, complemento, bairro, cidade, UF e ponto de referência. Se qualquer campo do endereço for preenchido, rua e número MUST ser obrigatórios. **Salvar cliente** MUST gravar cliente e endereço juntos (ou nada) e voltar à lista já atualizada. A seta no passo 2 SHALL voltar ao passo 1 mantendo o que foi digitado.

#### Scenario: Cadastro só com o passo 1
- **WHEN** a consultora preenche nome e WhatsApp, avança e salva com o endereço vazio
- **THEN** a cliente é gravada sem endereço e aparece na lista

#### Scenario: WhatsApp inválido
- **WHEN** ela digita "1199" no WhatsApp e toca em Continuar
- **THEN** o campo mostra "WhatsApp inválido" e o passo 2 não abre

#### Scenario: Nascimento no futuro
- **WHEN** ela informa uma data de nascimento posterior a hoje
- **THEN** o campo mostra "Data inválida" e o passo 2 não abre

#### Scenario: Endereço incompleto
- **WHEN** ela preenche só o bairro no passo 2 e salva
- **THEN** rua e número mostram "Obrigatório" e nada é gravado

#### Scenario: Falha ao salvar
- **GIVEN** a internet cai
- **WHEN** ela toca em Salvar cliente
- **THEN** aparece o aviso de erro, os dados digitados continuam na tela e nada é gravado pela metade

### Requirement: Preencher endereço pelo CEP
Ao completar os 8 dígitos do CEP, o app SHALL consultar o serviço público de CEP e preencher rua, bairro, cidade e UF, que continuam editáveis. Apenas o CEP MUST ser enviado ao serviço. Se o CEP não existir ou a consulta falhar, o app SHALL avisar e deixar os campos para preenchimento manual.

#### Scenario: CEP encontrado
- **WHEN** ela digita "01001-000"
- **THEN** rua, bairro, cidade e UF são preenchidos e o foco vai para o número

#### Scenario: CEP não encontrado
- **WHEN** ela digita um CEP que não existe
- **THEN** aparece "CEP não encontrado" e os campos ficam como estavam

### Requirement: Detalhes da cliente
O app SHALL mostrar, nos detalhes: iniciais, nome, o selo do saldo devedor (quando houver) e as opções **Dados cadastrais**, **Compras da cliente** (com quantidade de pedidos e total gasto) e **Nova venda**. Enquanto a fase de Vendas não existir, Compras da cliente e Nova venda MUST abrir a tela "em construção".

#### Scenario: Cliente devendo
- **GIVEN** a cliente tem R$ 120,00 de saldo devedor
- **WHEN** a consultora abre os detalhes
- **THEN** aparece o selo "Deve R$ 120,00"

#### Scenario: Cliente sem compras
- **WHEN** a consultora abre os detalhes de uma cliente sem vendas
- **THEN** Compras da cliente mostra "Nenhum pedido ainda" e não há selo de saldo

### Requirement: Dados cadastrais
O app SHALL mostrar, em leitura: nome, WhatsApp formatado, aniversário (dia e mês), endereço (CEP, bairro e cidade - UF, rua com número e complemento, ponto de referência) e observações. Campos vazios MUST ser omitidos; sem endereço, a seção mostra "Endereço não cadastrado". **Abrir WhatsApp** SHALL abrir a conversa com a cliente no WhatsApp. **Editar** SHALL abrir os dois passos já preenchidos, e salvar MUST atualizar os dados cadastrais, os detalhes e a lista.

#### Scenario: Abrir WhatsApp
- **GIVEN** a cliente tem WhatsApp 11987654321
- **WHEN** a consultora toca em Abrir WhatsApp
- **THEN** o WhatsApp abre na conversa com +55 11 98765-4321

#### Scenario: WhatsApp não instalado
- **GIVEN** não há WhatsApp nem navegador capaz de abrir o link
- **WHEN** ela toca em Abrir WhatsApp
- **THEN** aparece o aviso "Não foi possível abrir o WhatsApp"

#### Scenario: Editar e remover o endereço
- **GIVEN** a cliente tem endereço
- **WHEN** a consultora edita, apaga todos os campos do endereço e salva
- **THEN** a cliente fica sem endereço e os dados mostram "Endereço não cadastrado"

### Requirement: Integridade dos dados da cliente
O banco MUST recusar WhatsApp da cliente que não tenha só 10 ou 11 dígitos, nome vazio, UF fora do padrão de duas letras maiúsculas e data de nascimento no futuro.

#### Scenario: WhatsApp com máscara
- **WHEN** alguém tenta gravar a cliente com WhatsApp "(11) 98765-4321"
- **THEN** o banco recusa a gravação

### Requirement: Isolamento das clientes
Clientes, endereços, o resumo financeiro e a função de gravação MUST respeitar o isolamento por consultora: a consultora A nunca lê, cria, altera nem vincula clientes ou endereços da consultora B, e o usuário anônimo não acessa nada.

#### Scenario: Resumo de outra consultora
- **GIVEN** a consultora B tem clientes com saldo devedor
- **WHEN** a consultora A consulta o resumo de clientes
- **THEN** só aparecem as clientes de A

#### Scenario: Editar cliente de outra consultora pela função
- **GIVEN** A conhece o id de uma cliente de B
- **WHEN** A chama a função de gravação com esse id
- **THEN** a chamada falha e a cliente de B continua igual

#### Scenario: Endereço de outra consultora
- **GIVEN** A conhece o id de um endereço de B
- **WHEN** A tenta vincular esse endereço a uma cliente sua
- **THEN** o banco recusa

#### Scenario: Anônimo
- **WHEN** o usuário anônimo consulta clientes, endereços, o resumo ou chama a função
- **THEN** nada é retornado e nada é gravado

### Requirement: Compras da cliente
A tela **Compras da cliente** (aberta pelos detalhes da cliente) SHALL mostrar o total gasto e quanto está atrasado, pendente e pago (com a quantidade de parcelas de cada), filtrar as compras por status (com contagens), buscar pelo produto ou serviço comprado e listar as compras (nome do 1º item ou "N itens", unidades, data, valor e status) que abrem os detalhes da venda. **Nova Venda** SHALL abrir o pedido já com a cliente.

#### Scenario: Cliente sem compras
- **GIVEN** a cliente nunca comprou
- **WHEN** a consultora abre Compras da cliente
- **THEN** aparecem os totais zerados e o convite para registrar a primeira venda

#### Scenario: Nova venda pela cliente
- **WHEN** ela toca em Nova Venda
- **THEN** o pedido abre com a cliente já escolhida
