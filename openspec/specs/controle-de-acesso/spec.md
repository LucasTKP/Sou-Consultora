# controle-de-acesso Specification

## Purpose
Garante que só uma consultora com sessão ativa veja as telas internas do app, define para onde o app leva em cada situação de sessão e como a saída da conta encerra o acesso.

## Requirements

### Requirement: Sem sessão, só o login
O app MUST mostrar somente a tela de login para quem não tem sessão ativa, qualquer que seja a tela pedida.

#### Scenario: Abrir o app sem sessão
- **GIVEN** não há sessão salva no aparelho
- **WHEN** o app abre
- **THEN** a tela de login aparece

#### Scenario: Tentar abrir tela interna sem sessão
- **GIVEN** não há sessão ativa
- **WHEN** o app recebe um pedido para abrir a tela de Vendas
- **THEN** a tela de login aparece no lugar

### Requirement: Com sessão, direto para o Início
O app SHALL levar ao Início quem já tem sessão ativa e cadastro de consultora, sem passar pelo login. Com sessão e sem cadastro, o app MUST levar à tela de cadastro.

#### Scenario: Abrir o app com sessão salva
- **GIVEN** a consultora entrou anteriormente, a sessão é válida e o cadastro existe
- **WHEN** o app abre
- **THEN** o Início aparece sem mostrar o login

#### Scenario: Login concluído
- **GIVEN** a consultora já cadastrada está no login
- **WHEN** ela conclui a entrada com Google ou Apple
- **THEN** o Início aparece e o voltar do sistema não retorna ao login

#### Scenario: Pedir o login já com sessão
- **GIVEN** a consultora tem sessão ativa e cadastro
- **WHEN** o app recebe um pedido para abrir o login
- **THEN** o Início aparece no lugar

#### Scenario: Primeiro login sem cadastro
- **GIVEN** a pessoa nunca se cadastrou
- **WHEN** ela conclui a entrada com Google ou Apple
- **THEN** a tela de cadastro aparece

#### Scenario: Sem cadastro tentando abrir o app
- **GIVEN** a pessoa tem sessão e não tem cadastro
- **WHEN** o app recebe um pedido para abrir Vendas
- **THEN** a tela de cadastro aparece no lugar

### Requirement: Fim da sessão leva ao login
O app MUST levar para o login, descartando as telas abertas, sempre que a sessão terminar, seja por saída, expiração ou remoção da conta.

#### Scenario: Sessão expirada
- **GIVEN** a consultora está no detalhe de uma venda
- **WHEN** a sessão expira e não pode ser renovada
- **THEN** a tela de login aparece e o voltar do sistema não retorna ao detalhe

### Requirement: Sair da conta
O app SHALL permitir sair da conta pelo menu lateral, com confirmação, encerrando a sessão no Supabase e a conta Google conectada.

#### Scenario: Confirmar saída
- **GIVEN** o menu lateral está aberto
- **WHEN** a consultora toca em Sair da conta e confirma
- **THEN** a sessão é encerrada, o login aparece e a próxima entrada com Google pede a escolha da conta

#### Scenario: Desistir da saída
- **WHEN** a consultora toca em Sair da conta e cancela a confirmação
- **THEN** a sessão continua e a tela atual permanece

#### Scenario: Falha ao sair
- **GIVEN** não há conexão com a internet
- **WHEN** a consultora confirma a saída
- **THEN** a sessão local é encerrada mesmo assim e o login aparece

### Requirement: Verificação do cadastro
Enquanto confere se existe cadastro, o app SHALL mostrar uma tela de carregamento com a marca. Se a verificação falhar, o app MUST mostrar a mensagem de erro com a opção de tentar novamente, sem levar ao cadastro.

#### Scenario: Verificando
- **WHEN** a sessão começa e o cadastro ainda está sendo conferido
- **THEN** a tela de carregamento aparece

#### Scenario: Falha na verificação
- **GIVEN** não há conexão com a internet
- **WHEN** o app tenta conferir o cadastro
- **THEN** aparece a mensagem de erro com "Tentar novamente", e o cadastro não é aberto

#### Scenario: Tentar novamente
- **GIVEN** a verificação falhou
- **WHEN** a conexão volta e a consultora toca em "Tentar novamente"
- **THEN** o app segue para o Início ou para o cadastro, conforme o resultado

### Requirement: Cadastro da consultora
A tela de cadastro SHALL pedir o WhatsApp com DDD, além do nome quando o provedor de login não o informar, e MUST criar o registro da consultora. Só depois disso o app MUST levar ao Início.

#### Scenario: Cadastro com nome do Google
- **GIVEN** o login com Google informou o nome
- **WHEN** a pessoa informa um WhatsApp válido e toca em Continuar
- **THEN** o registro é criado com esse nome e esse WhatsApp, e o Início aparece

#### Scenario: Provedor sem nome
- **GIVEN** o login com Apple não informou o nome
- **WHEN** a tela de cadastro abre
- **THEN** ela pede também o nome completo, como campo obrigatório

#### Scenario: WhatsApp inválido
- **WHEN** a pessoa informa "(11) 9876" e toca em Continuar
- **THEN** o campo mostra "Informe o WhatsApp com DDD" e nada é gravado

#### Scenario: Falha ao gravar
- **GIVEN** a conexão cai
- **WHEN** a pessoa toca em Continuar
- **THEN** aparece uma mensagem de erro, os dados digitados permanecem e ela pode tentar de novo

#### Scenario: Voltar no cadastro
- **WHEN** a pessoa toca na seta de voltar do cadastro
- **THEN** a sessão é encerrada e o login aparece
