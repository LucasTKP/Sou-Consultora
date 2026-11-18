# Spec Delta

## MODIFIED Requirements

### Requirement: Menu lateral com o mapa completo
O app SHALL abrir, pelo ícone de menu das telas principais, um menu lateral com o nome e a foto da consultora, o atalho Ver perfil e os itens agrupados.

Grupos e itens:
- **Navegação principal:** Início, Vendas & Pedidos, Clientes, Produtos & Estoque, Serviços, Fornecedores & Marcas.
- **Gestão financeira:** A Receber / Cobranças (com um selo da quantidade de parcelas atrasadas, quando houver), A Pagar / Boletos, Financeiro & Relatórios.
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

#### Scenario: Selo de cobranças atrasadas
- **GIVEN** há 4 parcelas atrasadas
- **WHEN** a consultora abre o menu lateral
- **THEN** A Receber / Cobranças mostra o selo "4"; sem parcelas atrasadas, o selo não aparece
