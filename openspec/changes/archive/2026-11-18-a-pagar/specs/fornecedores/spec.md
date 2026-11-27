# Spec Delta

## MODIFIED Requirements

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
