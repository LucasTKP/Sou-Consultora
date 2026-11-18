# Spec Delta

## ADDED Requirements

### Requirement: Compras da cliente
A tela **Compras da cliente** (aberta pelos detalhes da cliente) SHALL mostrar o total gasto e quanto está atrasado, pendente e pago (com a quantidade de parcelas de cada), filtrar as compras por status (com contagens), buscar pelo produto ou serviço comprado e listar as compras (nome do 1º item ou "N itens", unidades, data, valor e status) que abrem os detalhes da venda. **Nova Venda** SHALL abrir o pedido já com a cliente.

#### Scenario: Cliente sem compras
- **GIVEN** a cliente nunca comprou
- **WHEN** a consultora abre Compras da cliente
- **THEN** aparecem os totais zerados e o convite para registrar a primeira venda

#### Scenario: Nova venda pela cliente
- **WHEN** ela toca em Nova Venda
- **THEN** o pedido abre com a cliente já escolhida
