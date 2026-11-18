# Design

## Context

- **Banco (já existe):**
  - `boletos` (`valor > 0`, `data_vencimento`, `forma_pagamento in (pix, boleto, transferencia)` nulo, `observacoes`, `comprovante_url`, `data_pagamento` nula = não pago), com RLS forçado, 4 policies e FK composta `(consultora_id, fornecedor_id) → fornecedores`;
  - bucket privado `comprovantes` (10 MB, JPEG/PNG/PDF) com policies por pasta `<auth.uid()>/`;
  - `resumo_fornecedores` já conta os boletos (em aberto, atrasados, vence hoje, pagos).
- **App:**
  - `ApiSupabase` tem `listar`, `buscarUm`, `inserir`, `atualizar`, `enviarArquivo`, `removerArquivos` e `urlAssinada`, mas **não** tem excluir linha;
  - `RepositorioFornecedores` (cache + `Stream`) e o filtro de mês `MesAno` (Vendas/A receber) existem; `TextoBusca` faz a busca sem acento;
  - `image_picker` e `FolhaFotoApp` (câmera/galeria) já são usados em Produtos; `url_launcher` já é dependência;
  - `/a-pagar` é rota "em construção" na casca (menu "A Pagar / Boletos"); Fornecedores tem **Ver em A pagar** apontando para ela.
- Motivação: `proposal.md`. Comportamento: `specs/a-pagar/spec.md` e `specs/fornecedores/spec.md`.

## Goals / Non-Goals

**Goals:**
- Uma leitura para a lista (boleto + nome da marca), sem N+1.
- Situação, filtros, contagens e textos do card como lógica pura no Model.
- A regra "data de pagamento nunca futura" garantida no banco (não só na tela).

**Non-Goals:**
- Pagamento parcial de boleto, juros/multa e boletos recorrentes.
- Ler o código de barras ou o PDF do boleto.
- Lembrete/notificação de vencimento (fica para Início/alertas).

## Decisions

### 1. Banco (`..._a_pagar.sql`)
- View `resumo_boletos` (`security_invoker`): colunas do boleto + `fornecedor_nome` e `fornecedor_ativo` (join pela FK composta). `revoke` de `anon, public`, `grant select` a `authenticated`.
- Trigger `before insert or update` em `boletos`: recusa `data_pagamento` depois de hoje em São Paulo (`SC400`, "A data do pagamento não pode ser no futuro.").
- Sem RPC: gravar, pagar, desfazer e excluir são `insert`/`update`/`delete` de uma linha só, cobertos pelas policies existentes. O app nunca envia `consultora_id`.
- Teste `13_a_pagar.sql`: view, trigger (hoje ok, amanhã recusa, desfazer = null ok), A × B (ler, alterar, pagar, excluir), FK com fornecedor de B, anon sem acesso à view, Storage na pasta de B recusado.

### 2. App
| Camada | Arquivo |
|---|---|
| api | `api_supabase.dart` ganha `excluir(tabela, coluna:, valor:)` |
| dto | `boleto_dto.dart` (espelho de `resumo_boletos`; `toJson` de gravação sem `consultora_id`) |
| model | `boleto.dart` (`ResumoBoleto` + `StatusBoleto`, textos do card e validações de valor/fornecedor/vencimento), `forma_pagamento_boleto.dart` (Pix, boleto, transferência), `filtro_boletos.dart` (status, mês, busca por marca/observação, fornecedor, contagens) |
| service | `servico_boletos.dart` (view, gravar, pagar/desfazer, excluir, comprovante no Storage) |
| repository | `repositorio_boletos.dart` (cache + `Stream`; depois de gravar, pagar, desfazer ou excluir recarrega também `RepositorioFornecedores`, para os números da marca) |
- UI `ui/modules/a_pagar/`:
  - `lista/` (na casca, pelo menu; e por cima, com seta de voltar e o nome da marca, só com os boletos de um fornecedor);
  - `formulario/` (novo e editar em 2 passos, `widgets/passo_dados.dart` e `widgets/passo_pagamento.dart`);
  - `detalhes/` (`widgets/folha_pagar_boleto.dart` com a data, `widgets/folha_opcoes_boleto.dart`, `widgets/folha_comprovante.dart` com câmera, galeria e PDF).
- Rotas: `/a-pagar` (lista na casca), `/a-pagar/novo[?fornecedor=<id>]`, `/a-pagar/fornecedor/:id` (lista por cima, só daquela marca; padrão "Todos os meses"), `/a-pagar/:id`, `/a-pagar/:id/editar`. Fornecedores → `/a-pagar/fornecedor/<id>` por cima (empurrar a lista da casca a partir de uma tela por cima misturaria as navegações); na volta, recarrega os detalhes.

### 3. Comprovante
- Caminho: `comprovantes/<auth.uid()>/boletos/<id do boleto>/<momento>.<jpg|png|pdf>`; `comprovante_url` guarda o caminho (nunca URL).
- Foto pelo `image_picker` (qualidade 80, lado máximo 2000 px); PDF pelo `file_picker` (`withData`, só `.pdf`). Limite de 10 MB validado no Model antes de enviar.
- Ordem ao anexar: envia o novo → grava o caminho no boleto → remove o antigo. Se a gravação falhar, remove o recém-enviado.
- **Ver comprovante**: URL assinada de 5 minutos aberta pelo `url_launcher` (o celular mostra a imagem ou o PDF).
- Excluir boleto: apaga a linha e depois o arquivo; se só a remoção do arquivo falhar, o boleto continua excluído e o erro vai para o log de depuração (arquivo órfão na pasta da própria consultora).

### 4. Pagar e desfazer
- Pagar = `update data_pagamento = <dia>`; a folha não deixa escolher dia futuro e o banco garante. Desfazer = `update data_pagamento = null` (com confirmação); forma e comprovante ficam.

## Risks / Trade-offs
- [Arquivo órfão] Remoção do Storage depois do `delete` pode falhar → aceita (pasta privada da própria consultora); o boleto nunca fica apontando para arquivo apagado.
- [Excluir sem lixeira] Excluir é definitivo → confirmação com o nome da marca e o valor.
- [file_picker] Dependência nova com código nativo → só o PDF usa; foto continua no `image_picker`.
