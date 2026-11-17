# Spec Delta

## Purpose

Define como a consultora se move entre os módulos do app: a barra inferior fixa, o menu lateral com o mapa completo, quais telas mostram a barra e o comportamento do botão voltar.

## ADDED Requirements

### Requirement: Barra inferior fixa
O app SHALL exibir, nas telas principais, uma barra inferior com sempre os mesmos 5 itens nesta ordem: Produtos, Clientes, Início (central e em destaque), Vendas e Financeiro.

#### Scenario: Ordem e destaque
- **WHEN** a consultora está em qualquer tela principal
- **THEN** a barra mostra Produtos, Clientes, Início, Vendas e Financeiro, com Início no centro em destaque

#### Scenario: Trocar de módulo pela barra
- **GIVEN** a consultora está no Início
- **WHEN** ela toca em Clientes
- **THEN** a tela de Clientes abre e o item Clientes fica marcado como ativo

### Requirement: Item ativo da barra
O app MUST marcar como ativo o item da barra correspondente ao módulo aberto, e nenhum item quando o módulo aberto não estiver na barra.

#### Scenario: Módulo fora da barra
- **WHEN** a consultora abre Serviços pelo menu lateral
- **THEN** a barra continua visível e nenhum item aparece como ativo

### Requirement: Telas principais e telas empilhadas
O app SHALL mostrar a barra inferior somente nas telas principais (a tela inicial de cada módulo). Telas de detalhe, cadastro e edição MUST abrir por cima, sem a barra e com a seta de voltar.

#### Scenario: Abrir um detalhe
- **GIVEN** a consultora está na lista de Clientes
- **WHEN** ela abre o detalhe de uma cliente
- **THEN** o detalhe aparece sem a barra inferior e com a seta de voltar

#### Scenario: Voltar de um detalhe
- **WHEN** a consultora toca na seta de voltar do detalhe
- **THEN** ela volta para a lista de Clientes com a barra inferior

### Requirement: Menu lateral com o mapa completo
O app SHALL abrir, pelo ícone de menu das telas principais, um menu lateral com o nome e a foto da consultora, o atalho Ver perfil e os itens agrupados.

Grupos e itens:
- **Navegação principal:** Início, Vendas & Pedidos, Clientes, Produtos & Estoque, Serviços, Fornecedores & Marcas.
- **Gestão financeira:** A Receber / Cobranças, A Pagar / Boletos, Financeiro & Relatórios.
- **Rodapé:** Configurações, Sair da conta e a versão do app.

#### Scenario: Navegar pelo menu
- **GIVEN** o menu lateral está aberto
- **WHEN** a consultora toca em Fornecedores & Marcas
- **THEN** o menu fecha e a tela de Fornecedores abre

#### Scenario: Item atual destacado
- **GIVEN** a consultora está no Início
- **WHEN** ela abre o menu lateral
- **THEN** o item Início aparece destacado

#### Scenario: Ver perfil e Configurações
- **WHEN** a consultora toca em Ver perfil ou em Configurações
- **THEN** a tela de Perfil abre

#### Scenario: Sem foto
- **GIVEN** a consultora não tem foto
- **WHEN** ela abre o menu lateral
- **THEN** o lugar da foto mostra as iniciais do nome

### Requirement: Módulo ainda não construído
O app SHALL abrir todo módulo do menu e da barra, mesmo os ainda não construídos. Um módulo não construído MUST mostrar o título do módulo e um aviso de que está em construção, sem erro.

#### Scenario: Abrir módulo em construção
- **WHEN** a consultora abre A Pagar antes da fase de boletos estar pronta
- **THEN** aparece a tela A Pagar com o aviso de que está em construção

### Requirement: Botão voltar do sistema
O botão voltar do Android MUST seguir esta ordem:
1. fechar a folha ou o menu aberto;
2. desempilhar a tela de detalhe;
3. em uma tela principal que não seja o Início, ir para o Início;
4. no Início, sair do app.

#### Scenario: Voltar com o menu aberto
- **GIVEN** o menu lateral está aberto
- **WHEN** a consultora aperta o voltar do sistema
- **THEN** o menu fecha e a tela atual permanece

#### Scenario: Voltar em tela principal
- **GIVEN** a consultora está na lista de Vendas
- **WHEN** ela aperta o voltar do sistema
- **THEN** o Início abre

#### Scenario: Voltar no Início
- **GIVEN** a consultora está no Início
- **WHEN** ela aperta o voltar do sistema
- **THEN** o app é fechado
