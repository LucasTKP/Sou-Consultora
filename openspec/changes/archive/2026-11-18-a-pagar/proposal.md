# Proposal

## Why

A consultora compra das marcas a prazo e paga por boleto. Hoje o app mostra quantos boletos cada fornecedor tem, mas não deixa lançar, acompanhar nem dar baixa neles — e esquecer um boleto custa juros e o crédito com a marca. A pagar fecha o lado das despesas que Fornecedores já começou.

## What Changes

- **A pagar** (menu → A pagar): boletos do mês pelo vencimento (padrão mês atual, opção "Todos os meses"); busca pela marca ou pela observação (sem diferenciar acentos); status (Todos, Pendente, Vence hoje, Atrasado, Pago, com contagens); quantidade ("4 boletos"); card com iniciais e nome da marca, selo e o vencimento ("Hoje (12/11/2024)", "18/11/2024 (em 6 dias)", "Venceu em 05/11/2024 (7 dias)" ou "Liquidado em 01/11/2024 via Pix") com o valor. Atalho **+** e botão **Novo boleto**.
- **Novo / editar boleto** em 2 passos: (1) fornecedor ativo (atalho para cadastrar marca), valor e vencimento, obrigatórios; (2) confere marca, vencimento e valor, forma de pagamento opcional (Pix, boleto, transferência) e observação. **Salvar boleto** grava e volta.
- **Detalhes do boleto**: marca, valor, fornecedor, vencimento, forma, status, observação e o comprovante (quando houver). **Confirmar pagamento** abre uma folha com a data (hoje, nunca futura) e quita o boleto inteiro (não há pagamento parcial). **Mais opções**: editar, baixar/anexar comprovante, desfazer pagamento (boleto pago), excluir (com confirmação).
- **Comprovante**: foto (câmera ou galeria) ou PDF, guardado no bucket privado `comprovantes` em `<auth.uid()>/boletos/`; **Ver** abre o arquivo por URL assinada de curta duração; anexar outro substitui o anterior; excluir o boleto apaga o arquivo.
- **Fornecedores**: **Ver em A pagar** abre A pagar já filtrado pela marca (antes: tela em construção).
- **Banco:** view `resumo_boletos` (boleto + nome da marca, `security_invoker`) e trigger que recusa data de pagamento futura (dia de São Paulo). A tabela `boletos`, o RLS e o bucket já existem.

## Capabilities

### New Capabilities
- `a-pagar`: lançar, acompanhar, quitar (e desfazer), editar e excluir os boletos das marcas, com comprovante em foto ou PDF.

### Modified Capabilities
- `fornecedores`: **Ver em A pagar** passa a abrir A pagar filtrado pela marca.

## Impact

- **Banco:** `supabase/migrations/..._a_pagar.sql` e `supabase/tests/13_a_pagar.sql` (view, trigger da data, isolamento A × B × anon, FK composta com fornecedor de outra consultora, Storage na pasta de outra consultora).
- **App:** core (boleto: dto, model, filtro, service, repository + DI); `ui/modules/a_pagar/` (lista, formulário em 2 passos, detalhes com a folha de pagamento e as opções); rotas `/a-pagar`, `/a-pagar/novo`, `/a-pagar/fornecedor/:id`, `/a-pagar/:id` e `/a-pagar/:id/editar`; Fornecedores (Ver em A pagar).
- **Dependência nova:** `file_picker` (escolher o PDF). Foto continua pelo `image_picker`.
- **Testes:** unitários, widget e E2E-11.
