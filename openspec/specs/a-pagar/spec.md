# a-pagar Specification

## Purpose

Permite à consultora lançar os boletos que deve às marcas, ver o que vence e o que atrasou, dar baixa (e desfazer um engano), guardar o comprovante e corrigir ou apagar um boleto.

## Requirements

### Requirement: Listar boletos
O app SHALL mostrar, em A pagar, os boletos com vencimento no mês escolhido (padrão: mês atual; opção "Todos os meses") em cards com iniciais e nome da marca, o selo de situação e o vencimento com o valor, e a quantidade encontrada ("1 boleto", "4 boletos"). SHALL buscar pela marca ou pela observação (sem diferenciar maiúsculas nem acentos), filtrar por status (Todos, Pendente, Vence hoje, Atrasado, Pago, com contagens) e ordenar por vencimento mais próximo (padrão), vencimento mais distante, maior valor ou menor valor. Quando aberta a partir de um fornecedor, SHALL mostrar só os boletos dele.

#### Scenario: Card de boleto atrasado
- **GIVEN** um boleto de R$ 310,00 da Eudora venceu em 05/11 sem pagamento
- **WHEN** a consultora abre A pagar em 12/11
- **THEN** o card mostra "Atrasado", "Venceu em 05/11/2024 (7 dias)" e "R$ 310,00"

#### Scenario: Card de boleto pago
- **GIVEN** o boleto da Avon foi pago em 01/11 via Pix
- **THEN** o card mostra "Pago" e "Liquidado em 01/11/2024 via Pix"

#### Scenario: Busca pela observação
- **WHEN** ela digita "ciclo 15"
- **THEN** aparecem só os boletos com "Ciclo 15" na observação

#### Scenario: Aberta pelo fornecedor
- **WHEN** ela toca em Ver em A pagar nos detalhes da Natura
- **THEN** A pagar mostra só os boletos da Natura

### Requirement: Situação do boleto
A situação MUST ser calculada e nunca gravada: "Pago" quando há data de pagamento; "Atrasado" quando não pago e o vencimento é antes de hoje; "Vence hoje" quando não pago e vence hoje; "Pendente" no resto. "Hoje" MUST ser o dia em `America/Sao_Paulo`.

#### Scenario: Vence hoje
- **GIVEN** um boleto não pago vence hoje
- **THEN** a situação é "Vence hoje", não "Pendente" nem "Atrasado"

### Requirement: Lançar e editar boleto
O cadastro SHALL ter 2 passos. Passo 1: fornecedor (só os ativos; na edição, o atual mesmo em espera), valor e vencimento, todos obrigatórios, com atalho para cadastrar uma marca. Passo 2: confere marca, vencimento e valor; forma de pagamento opcional (Pix, boleto ou transferência) e observação opcional. O valor MUST ser maior que zero. **Salvar boleto** SHALL gravar e voltar; na edição, SHALL voltar aos detalhes recarregados.

#### Scenario: Campos obrigatórios
- **WHEN** ela toca em Continuar sem escolher a marca e sem valor
- **THEN** o passo 1 avisa nos dois campos e não avança

#### Scenario: Salvar
- **WHEN** ela salva um boleto da Natura de R$ 680,00 para 25/11
- **THEN** ele aparece em A pagar como "Pendente"

### Requirement: Detalhes do boleto
O app SHALL mostrar a marca, o valor, o fornecedor, o vencimento, a forma de pagamento (quando houver), o selo de situação, a observação (quando houver), a data de pagamento (quando pago) e o comprovante (quando anexado). **Confirmar pagamento** SHALL aparecer só em boleto não pago. **Mais opções** SHALL oferecer editar, baixar/anexar comprovante, desfazer pagamento (só em boleto pago) e excluir.

#### Scenario: Boleto pago
- **GIVEN** o boleto está pago
- **THEN** não aparece Confirmar pagamento e Mais opções oferece Desfazer pagamento

### Requirement: Pagar boleto
**Confirmar pagamento** SHALL abrir uma folha com a data do pagamento (padrão hoje) e quitar o boleto inteiro; não existe pagamento parcial de boleto. A data MUST NOT ser futura. **Desfazer pagamento** SHALL pedir confirmação e apagar a data de pagamento, e o boleto volta a Pendente, Vence hoje ou Atrasado.

#### Scenario: Pagar com a data de ontem
- **WHEN** ela confirma o pagamento com a data de ontem
- **THEN** o boleto fica "Pago" com "Liquidado em" ontem

#### Scenario: Data futura
- **WHEN** alguém grava um pagamento com data de amanhã
- **THEN** o banco recusa e o boleto continua não pago

#### Scenario: Desfazer
- **GIVEN** um boleto vencido foi marcado como pago por engano
- **WHEN** ela desfaz o pagamento e confirma
- **THEN** o boleto volta a "Atrasado"

### Requirement: Comprovante do boleto
A consultora SHALL poder anexar ao boleto uma foto (câmera ou galeria) ou um PDF, que fica em armazenamento privado na pasta dela. Anexar de novo MUST substituir o anterior. **Ver comprovante** SHALL abrir o arquivo por um link temporário. Excluir o boleto MUST apagar o arquivo.

#### Scenario: Anexar PDF
- **WHEN** ela anexa o PDF do comprovante do banco
- **THEN** os detalhes mostram o comprovante e Ver comprovante abre o PDF

### Requirement: Excluir boleto
**Excluir boleto** SHALL pedir confirmação e apagar o boleto (pago ou não) e o comprovante dele; a lista e os números do fornecedor MUST ser atualizados.

#### Scenario: Excluir
- **WHEN** ela exclui um boleto e confirma
- **THEN** ele some de A pagar e o fornecedor deixa de contá-lo

### Requirement: Isolamento dos boletos
Boletos, a view de boletos e os comprovantes MUST respeitar o isolamento por consultora: A nunca lê, altera, paga nem apaga boletos de B, não lança boleto para fornecedor de B, não lê nem grava arquivos na pasta de B, e o anônimo não acessa nada.

#### Scenario: Boleto com fornecedor de outra consultora
- **WHEN** A grava um boleto com o fornecedor de B
- **THEN** o banco recusa

#### Scenario: Anônimo
- **WHEN** o anônimo lê a view de boletos ou os comprovantes
- **THEN** o banco recusa
