# conta-da-consultora Specification

## Purpose
Cobre o ciclo de vida da conta da consultora no banco: criação do registro com as categorias iniciais e remoção completa de todos os dados quando ela apaga a conta.

## Requirements

### Requirement: Registro da consultora vinculado ao login
O sistema SHALL permitir que a consultora autenticada crie um único registro próprio, identificado pelo mesmo id do login, com nome e WhatsApp obrigatórios.

#### Scenario: Primeiro cadastro
- **GIVEN** a consultora autenticou e ainda não tem registro
- **WHEN** ela grava o registro com nome e WhatsApp
- **THEN** o registro é criado com o id do login dela

#### Scenario: Registro com id de outro usuário
- **WHEN** a consultora tenta criar um registro com id diferente do próprio login
- **THEN** o banco recusa a gravação

#### Scenario: Segundo registro
- **GIVEN** a consultora já tem registro
- **WHEN** ela tenta criar outro
- **THEN** o banco recusa a gravação

### Requirement: Categorias padrão copiadas no cadastro
O sistema SHALL criar, para cada nova consultora, cópias próprias das categorias padrão de produto e de serviço.

#### Scenario: Consultora recém-cadastrada
- **WHEN** o registro da consultora é criado
- **THEN** ela passa a ter as categorias padrão de produto e de serviço como dona, marcadas como padrão

#### Scenario: Categorias independentes
- **GIVEN** A e B foram cadastradas
- **WHEN** A renomeia uma categoria padrão
- **THEN** a categoria correspondente de B não muda

### Requirement: Apagar a conta remove todos os dados
O sistema SHALL permitir que a consultora apague a própria conta, removendo o login e todos os registros dela em todas as tabelas.

#### Scenario: Consultora apaga a conta
- **GIVEN** A tem clientes, produtos, lotes, vendas e boletos
- **WHEN** A apaga a própria conta
- **THEN** o login de A deixa de existir e nenhuma linha de A permanece em nenhuma tabela

#### Scenario: Dados de outras consultoras preservados
- **WHEN** A apaga a própria conta
- **THEN** todos os dados de B permanecem intactos

#### Scenario: Apagar conta de outra consultora
- **WHEN** A tenta apagar a conta de B
- **THEN** a operação é recusada e a conta de B permanece

#### Scenario: Usuário anônimo tenta apagar conta
- **WHEN** um usuário sem sessão chama a remoção de conta
- **THEN** a operação é recusada

### Requirement: Marcas escolhidas no cadastro viram fornecedores
A tela de cadastro SHALL perguntar, de forma opcional, quais marcas a consultora vende, entre Natura, Avon, O Boticário, Eudora, Tupperware e Mary Kay. O app MUST criar um fornecedor para cada marca marcada, com o nome da marca, antes de liberar o app. Marcar nenhuma marca MUST NOT impedir o cadastro, e falha ao criar uma marca MUST NOT bloquear a entrada.

#### Scenario: Cadastro com marcas
- **GIVEN** a consultora marcou Natura e Mary Kay no cadastro
- **WHEN** ela conclui o cadastro
- **THEN** os fornecedores "Natura" e "Mary Kay" já existem quando o Início abre

#### Scenario: Cadastro sem marcas
- **GIVEN** a consultora não marcou nenhuma marca
- **WHEN** ela conclui o cadastro
- **THEN** o cadastro é concluído e nenhum fornecedor é criado

#### Scenario: Falha ao criar uma marca
- **GIVEN** a consultora marcou uma marca e a criação do fornecedor falha
- **WHEN** ela conclui o cadastro
- **THEN** o app abre normalmente e ela pode cadastrar a marca depois em Fornecedores
