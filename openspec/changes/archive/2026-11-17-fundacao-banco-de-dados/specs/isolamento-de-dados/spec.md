# Spec Delta

## Purpose

Garante que cada consultora só enxerga, altera e referencia os próprios dados — em tabelas e arquivos — e que nenhum usuário anônimo acessa dado algum.

## ADDED Requirements

### Requirement: Leitura restrita à própria consultora
O sistema MUST retornar, em qualquer tabela, somente as linhas cuja dona é a consultora autenticada.

#### Scenario: Consultora lista os próprios dados
- **GIVEN** a consultora A tem 3 clientes e a consultora B tem 2 clientes
- **WHEN** A consulta a tabela de clientes
- **THEN** o resultado contém exatamente as 3 clientes de A

#### Scenario: Consultora busca registro de outra pelo id
- **GIVEN** B tem uma venda com id conhecido
- **WHEN** A consulta essa venda pelo id
- **THEN** o resultado é vazio

### Requirement: Gravação restrita à própria consultora
O sistema MUST impedir que uma consultora insira, altere ou apague linhas de outra consultora.

#### Scenario: Inserir em nome de outra consultora
- **WHEN** A tenta inserir um produto informando o identificador de B como dona
- **THEN** o banco recusa a gravação

#### Scenario: Alterar ou apagar dado de outra consultora
- **WHEN** A tenta alterar ou apagar um cliente de B
- **THEN** nenhuma linha é afetada e o cliente de B permanece igual

#### Scenario: Transferir registro para outra consultora
- **WHEN** A tenta alterar a dona de um registro próprio para B
- **THEN** o banco recusa a alteração

### Requirement: Dona preenchida automaticamente
O sistema MUST definir a dona de toda linha nova como a consultora autenticada, sem que o app precise informá-la.

#### Scenario: Inserção sem informar a dona
- **WHEN** A insere um cliente sem informar a dona
- **THEN** o cliente é gravado com A como dona

### Requirement: Referências só entre dados da mesma consultora
O sistema MUST recusar qualquer vínculo entre registros de consultoras diferentes.

#### Scenario: Venda apontando para cliente de outra consultora
- **GIVEN** A conhece o id de uma cliente de B
- **WHEN** A tenta gravar uma venda vinculada a essa cliente
- **THEN** o banco recusa a gravação

#### Scenario: Lote apontando para produto de outra consultora
- **WHEN** A tenta gravar um lote de estoque com um produto de B
- **THEN** o banco recusa a gravação

### Requirement: Nenhum acesso anônimo
O sistema MUST negar a usuários não autenticados a leitura e a gravação de qualquer tabela.

#### Scenario: Leitura anônima
- **WHEN** um usuário sem sessão consulta qualquer tabela da consultora
- **THEN** o acesso é negado ou o resultado é vazio

#### Scenario: Gravação anônima
- **WHEN** um usuário sem sessão tenta inserir em qualquer tabela
- **THEN** o banco recusa a gravação

### Requirement: Nenhum dado compartilhado entre consultoras
O sistema MUST NOT manter linhas visíveis para mais de uma consultora, inclusive dados padrão do sistema.

#### Scenario: Categorias padrão
- **GIVEN** A e B estão cadastradas
- **WHEN** A consulta as categorias
- **THEN** só aparecem categorias cuja dona é A

### Requirement: Arquivos privados por consultora
O sistema MUST guardar fotos e comprovantes em áreas privadas, acessíveis somente pela consultora dona do arquivo.

#### Scenario: Envio para a própria pasta
- **WHEN** A envia uma foto para a própria pasta
- **THEN** o envio é aceito

#### Scenario: Envio ou leitura na pasta de outra consultora
- **WHEN** A tenta enviar, ler, substituir ou apagar um arquivo na pasta de B
- **THEN** a operação é negada

#### Scenario: Acesso anônimo a arquivo
- **WHEN** um usuário sem sessão tenta ler um arquivo de qualquer consultora
- **THEN** o acesso é negado

### Requirement: Isolamento comprovado por testes automatizados
O sistema MUST ter testes automatizados que comprovem o isolamento em todas as tabelas e áreas de arquivo, e esses testes MUST passar antes de qualquer migração ser aplicada.

#### Scenario: Nova tabela sem isolamento
- **GIVEN** uma migração cria uma tabela sem as regras de isolamento
- **WHEN** a suíte de testes do banco é executada
- **THEN** a suíte falha apontando a tabela
