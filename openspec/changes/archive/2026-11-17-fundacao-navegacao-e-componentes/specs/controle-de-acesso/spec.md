# Spec Delta

## Purpose

Garante que só uma consultora com sessão ativa veja as telas internas do app, define para onde o app leva em cada situação de sessão e como a saída da conta encerra o acesso.

## ADDED Requirements

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
O app SHALL levar ao Início quem já tem sessão ativa, sem passar pelo login.

#### Scenario: Abrir o app com sessão salva
- **GIVEN** a consultora entrou anteriormente e a sessão é válida
- **WHEN** o app abre
- **THEN** o Início aparece sem mostrar o login

#### Scenario: Login concluído
- **GIVEN** a consultora está no login
- **WHEN** ela conclui a entrada com Google ou Apple
- **THEN** o Início aparece e o voltar do sistema não retorna ao login

#### Scenario: Pedir o login já com sessão
- **GIVEN** a consultora tem sessão ativa
- **WHEN** o app recebe um pedido para abrir o login
- **THEN** o Início aparece no lugar

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
