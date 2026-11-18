# Spec Delta

## MODIFIED Requirements

### Requirement: Listar recebimentos
O app SHALL mostrar, em A receber, as parcelas com vencimento no mês escolhido (padrão: mês atual; opção "Todos os meses") em cards com iniciais e nome da cliente, qual parcela ("Parcela 2/2" ou "Parcela única"), o selo de situação ("Atrasado (dd/mm)", "Vence hoje", "Venc. dd/mm" ou "Pago em dd/mm") e o valor (o saldo, se não estiver paga), com a quantidade encontrada. SHALL buscar por cliente ou produto/serviço (sem acento), filtrar por status (Todos, A receber, Atrasado, Vence hoje, Pago, com contagens) e ordenar por vencimento ou valor. Aberta pelo Início com um status (Atrasado em **Cobrar agora**, Pago em **Recebido**), SHALL já vir com esse status e em "Todos os meses".

#### Scenario: Parcela vencida
- **GIVEN** a parcela 2/2 venceu em 15/10 sem pagamento
- **WHEN** a consultora abre A receber em outubro
- **THEN** o card mostra "Atrasado (15/10)" e o saldo

#### Scenario: Busca pelo produto
- **WHEN** ela digita "lily"
- **THEN** aparecem só as parcelas de vendas com "Kit Lily"

#### Scenario: Cobrar agora
- **GIVEN** há parcelas atrasadas de outubro e de novembro
- **WHEN** a consultora toca em Cobrar agora no Início
- **THEN** A receber abre em Atrasado e Todos os meses, com as parcelas dos dois meses
