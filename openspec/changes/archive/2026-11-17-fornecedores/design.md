# Design

## Context

- **Banco:**
  - `fornecedores` já existe (`nome` não vazio, `ramo`, `contato`, `telefone`, `observacoes`, `ativo default true`, `created_at`), com RLS forçado, 4 policies e `unique (consultora_id, id)`;
  - `telefone` é texto livre (sem formato) e não há unicidade de nome;
  - `boletos` existe (`valor > 0`, `data_vencimento`, `data_pagamento` nula = não pago, FK composta para `fornecedores`), mas o app ainda não grava boletos;
  - fornecedor com boletos ou produtos não pode ser apagado (FK sem cascade), o que já está coberto pelo spec `modelo-de-dados`.
- **App:**
  - `ApiSupabase` expõe `listar`, `buscarUm`, `inserir` e `atualizar`, o que basta para fornecedores (uma tabela só, sem RPC);
  - `RepositorioClientes` é o modelo de repositório com cache e `Stream`;
  - `ServicoWhatsapp`, `Telefone` (model), `TextoBusca` (busca sem acento), `FormatadorTelefone` e as máscaras já existem;
  - `/fornecedores` é uma rota "em construção" dentro do shell, aberta pelo menu lateral ("Fornecedores & Marcas").
- **Componentes prontos em `ui/widgets/`:**
  - `CampoBuscaApp`, `CampoSelecaoApp`, `CampoTextoApp`, `AreaTextoApp`;
  - `CartaoListaApp`, `CartaoApp`, `SeloStatusApp`, `AvatarApp`;
  - `EstadoVazioApp`, `EstadoErroApp`, `EstadoCarregandoApp`, `BotaoFlutuanteApp`, `BotaoApp`, `CabecalhoApp`.
  - Não existe interruptor (switch). Ele é criado nesta fase, para o "Em espera".
- Motivação: `proposal.md`. Comportamento: `specs/fornecedores/spec.md`.

## Goals / Non-Goals

**Goals:**
- Uma única leitura para a lista (fornecedor + números dos boletos), sem N+1.
- Status, filtros e contagens como lógica pura no Model, testável sem Flutter.
- Nome repetido recusado pelo banco e traduzido para uma mensagem clara.

**Non-Goals:**
- Paginação e busca no servidor (uma consultora tem poucas dezenas de marcas).
- Foto/logo e e-mail do fornecedor.
- Lista e cadastro de boletos (fase de A pagar). **Ver em A pagar** só navega para `/a-pagar`.
- Apagar fornecedor.

## Decisions

### 1. View `resumo_fornecedores` para a lista e os detalhes
A view usa `security_invoker = true` e tem uma linha por fornecedor, com:

- `id`, `nome`, `ramo`, `contato`, `telefone`, `observacoes`, `ativo`, `created_at`;
- `qtd_em_aberto`, `valor_em_aberto`: boletos com `data_pagamento is null`;
- `qtd_atrasados`, `valor_atrasado`: em aberto com `data_vencimento < hoje`;
- `qtd_vence_hoje`: em aberto com `data_vencimento = hoje`;
- `qtd_pagos`, `valor_pagos`: boletos com `data_pagamento` preenchida.

Valores em `numeric(12, 2)` com `coalesce(..., 0)`, quantidades em `integer`. "Hoje" é `(now() at time zone 'America/Sao_Paulo')::date`, como em `resumo_clientes`.

- **Por quê:** a lista mostra boletos em aberto e o selo "Vence hoje" de todas as marcas de uma vez. A view herda o RLS das tabelas e concentra a regra num só lugar, que a fase de A pagar vai reaproveitar.
- **Detalhes:** usam a mesma linha da view, porque todos os campos do fornecedor já estão nela. Não precisa de uma segunda consulta.
- **Alternativa descartada:** buscar boletos no app e somar. Repetiria a regra de status em vários lugares.

### 2. Gravação direta na tabela, sem RPC
`inserir('fornecedores', dados)` para criar e `atualizar('fornecedores', dados, coluna: 'id', valor: id)` para editar.

- Os dados nunca incluem `consultora_id`, `id` nem `created_at`: o default `auth.uid()` preenche e o RLS confere.
- Textos opcionais vazios viram `null` no Model antes de enviar.
- `ativo` só é enviado na edição.
- No update com id de outra consultora, o RLS esconde a linha, o `.single()` falha e o erro vira `FalhaApp`.
- **Por quê:** é uma tabela só, sem gravação em várias tabelas que precise de transação. Uma RPC seria código a mais sem ganho.

### 3. Migração `..._fornecedores.sql`
- Antes, normaliza dados que já existam: `update fornecedores set telefone = nullif(regexp_replace(telefone, '\D', '', 'g'), '')`. Se o resultado não tiver 10 ou 11 dígitos, vira `null`. O remoto ainda não tem fornecedores, mas a migração não pode quebrar se tiver.
- `check (telefone is null or telefone ~ '^[0-9]{10,11}$')`.
- Índice único `fornecedores (consultora_id, lower(btrim(nome)))`, que dá nomes únicos por consultora sem diferenciar maiúsculas.
- View da decisão 1, com `revoke all ... from anon, public` e `grant select ... to authenticated`.
- Índice `boletos (fornecedor_id)` já existe. Também cria `boletos (consultora_id, data_vencimento) where data_pagamento is null`, se ainda não existir, para "vence hoje" e "atrasados".
- Antes de aplicar, conferir se `testes.popular` (em `supabase/tests/auxiliares`) grava fornecedor com telefone compatível (hoje grava só o nome).

### 4. Nome repetido → `FalhaValidacao`
- Nova `FalhaValidacao` em `core/erros/falha_app.dart`.
- No `mapeador_falhas`, `PostgrestException` com `code == '23505'` vira `FalhaValidacao(mensagemDuplicado)`. O service informa essa mensagem ("Já existe um fornecedor com esse nome.") por um parâmetro opcional de `executarComFalha`.
- O cubit do formulário mostra a falha como aviso e mantém os campos, como nas outras falhas ao salvar.

### 5. Camadas no app
| Camada | Arquivo | Responsabilidade |
|---|---|---|
| dto | `core/dto/resumo_fornecedor_dto.dart` | linha da view + `paraModel` (numeric como `int`, `double` ou `String`) |
| model | `core/model/fornecedor.dart` | dados editáveis (`nome`, `ramo`, `contato`, `telefone`, `observacoes`, `ativo`), `validarNome`, `validarTelefone` (reusa `Telefone`), `paraGravar()` com textos vazios → `null` |
| model | `core/model/resumo_fornecedor.dart` | `ResumoFornecedor` (fornecedor + números dos boletos + `criadoEm`) e `StatusFornecedor` (`venceHoje`, `emEspera`, `ativo`) com prioridade; `iniciais` (até 3 letras, ex.: "NAT"), `combinaBusca` (via `TextoBusca`), `textoBoletosEmAberto` |
| model | `core/model/filtro_fornecedores.dart` | `StatusFiltroFornecedor` (todos, ativos, em espera, vence hoje), contagens e a função pura `filtrar(lista, status, busca, ordem)` |
| model | `core/model/ordem_nome.dart` | `OrdemNome` (A-Z / Z-A), movido de `filtro_clientes.dart` para ser compartilhado |
| service | `core/service/servico_fornecedores.dart` | `listarResumos`, `buscarResumo(id)`, `criar`, `atualizar` via `ApiSupabase`, devolvendo `Resultado` |
| repository | `core/repository/repositorio_fornecedores.dart` | cache + `Stream<List<ResumoFornecedor>>`; recarrega a lista após salvar; limpa o cache quando a sessão termina (igual a `RepositorioClientes`); `abrirWhatsapp` repassa ao `ServicoWhatsapp` |

- Os novos itens são registrados no `injetor`.
- Os erros passam por `mapeador_falhas`.
- A `iniciais` do fornecedor é diferente da de cliente (que usa primeiro e último nome). Para marca, usa as 3 primeiras letras de uma palavra ("NAT") ou as iniciais de até 3 palavras ("O Boticário" → "OB", "Avon / Eudora" → "AE"). A regra fica no Model.

### 6. Telas (`ui/modules/fornecedores/`)
| Pasta | Rota | Observações |
|---|---|---|
| `lista/` | `/fornecedores` (shell) | `CabecalhoApp` com menu; `CampoBuscaApp`; `CampoSelecaoApp` de status com contagens; "N fornecedores" + botão de ordem; `BotaoFlutuanteApp` "Fornecedor" acima da barra (`MediaQuery.paddingOf(context).bottom`, como na correção de Clientes); `widgets/cartao_fornecedor.dart` com iniciais, nome, boletos em aberto e selo |
| `formulario/` | `/fornecedores/novo` e `/fornecedores/:id/editar` (raiz) | tela única; título "Novo Fornecedor" ou "Editar Fornecedor"; interruptor **Em espera** só na edição; **Salvar** e **Cancelar** no rodapé; erros por campo no estado |
| `detalhes/` | `/fornecedores/:id` (raiz) | cartão de identidade (iniciais, nome, ramo, selo, "Parceiro desde"); cartão Boletos com os 3 blocos (em aberto, pagos, atrasados) e **Ver em A pagar**; cartão de contato (campos vazios omitidos, botão **WhatsApp**); **Editar fornecedor** e, na volta, recarrega |

- Widget novo e reutilizável: `ui/widgets/formularios/interruptor_app.dart`, um `Switch` do Material com as cores do app, rótulo e descrição (os outros campos também são Material).
- O mapeamento de `StatusFornecedor` para texto e cor fica no card (`lista/widgets/`), e os detalhes reusam o mesmo mapeamento.

### 7. Navegação
- Troca a rota "em construção" de `/fornecedores` pela lista.
- Cria `RotasApp.novoFornecedor`, `detalhesFornecedor(id)` e `editarFornecedor(id)` no navegador raiz.
- **Ver em A pagar** faz `context.go(RotasApp.aPagar)`. Por enquanto é a tela "em construção". A fase de A pagar troca isso por um filtro da marca.

## Risks / Trade-offs

- [Índice único com dados duplicados no remoto] → a migração falharia. Hoje o remoto não tem fornecedores, mas o plano de migração confere isso antes do `db push`.
- [Telefone normalizado para `null` na migração] → só afeta registros com telefone inválido, que hoje não existem.
- [Fuso de "hoje"] → mesmo trade-off de `resumo_clientes`: diferença de no máximo um dia perto da meia-noite fora do Brasil.
- [Mover `OrdemNome`] → mexe em Clientes. Os testes de Clientes cobrem a mudança, que é só de import.

## Migration Plan

1. `supabase db reset && supabase test db` local, com os testes novos passando.
2. Conferir no remoto que não há fornecedores com nome repetido nem telefone fora do formato (`select` simples).
3. Aplicar no remoto (`supabase db push`) **só com a confirmação do dono do projeto**.
4. Rollback: uma migração inversa que derruba a view, o índice único e o CHECK. Não há perda de dados.
