# Design

## Context

- **Banco:**
  - `clientes` e `enderecos` já existem, com RLS forçado, 4 policies e FK composta `(consultora_id, endereco_id)` `on delete set null`;
  - `clientes.whatsapp` só exige não ser vazio (sem formato);
  - `vendas`, `parcelas` e `pagamentos_parcela` existem, mas o app ainda não os grava.
- **App:**
  - `ApiSupabase` expõe `tabela`, `rpc`, `buscarUm`, `inserir` e `atualizar`;
  - `RepositorioConsultora` é o modelo de repositório com cache e `Stream`;
  - `/clientes` é uma rota "em construção" dentro do shell.
- **Componentes prontos em `ui/widgets/`:**
  - `CampoBuscaApp`, `CampoSelecaoApp`, `CampoDataApp`, `AreaTextoApp`, `CampoTextoApp`;
  - `CartaoListaApp`, `SeloStatusApp`, `AvatarApp`, `IndicadorPassosApp`, `TituloSecaoApp`;
  - `EstadoVazioApp`, `EstadoErroApp`, `EstadoCarregandoApp`, `BotaoFlutuanteApp`.
- Motivação: `proposal.md`. Comportamento: `specs/clientes/spec.md`.

## Goals / Non-Goals

**Goals:**
- Uma única leitura para a lista (cliente + números financeiros), sem N+1.
- Gravar cliente e endereço de forma atômica.
- Status, filtros e aniversário como lógica pura no Model, testável sem Flutter.

**Non-Goals:**
- Paginação e busca no servidor. A carteira de uma consultora tem dezenas ou centenas de clientes, então a lista vem inteira e é filtrada em memória.
- Tela Compras da cliente e Nova venda (fase de Vendas).
- Apagar cliente.

## Decisions

### 1. View `resumo_clientes` para a lista e os detalhes
A view usa `security_invoker = true` e tem uma linha por cliente, com:

- `id`, `nome`, `whatsapp`, `data_nascimento`, `created_at`;
- `qtd_compras`, `total_compras`, `ultima_compra`, a partir de `vendas`;
- `saldo_devedor`, `valor_atrasado`, `valor_vence_hoje`, a partir das parcelas menos os pagamentos.

O saldo de cada parcela é `valor − coalesce(soma dos pagamentos, 0)` e só conta quando é maior que 0. "Hoje" é `(now() at time zone 'America/Sao_Paulo')::date`, o mesmo dia que a consultora vê.

- **Por quê:** a lista precisa dos números financeiros de todas as clientes de uma vez. Uma view herda o RLS das tabelas e mantém o cálculo num só lugar, que a fase de Vendas vai reaproveitar.
- **Alternativa descartada:** calcular no app buscando parcelas e pagamentos. Traz muitas linhas e repete a regra de status em vários lugares.

### 2. RPC `salvar_cliente` para criar e editar
```
salvar_cliente(p_id uuid, p_nome text, p_whatsapp text, p_data_nascimento date,
               p_observacoes text, p_endereco jsonb) returns uuid
```
- A função é `security invoker` e roda numa única transação.
- Não recebe `consultora_id`: o default `auth.uid()` preenche e o RLS confere.
- `execute` é revogado de `anon` e `public` e concedido a `authenticated`.
- Fluxo:
  - `p_id` nulo → insere a cliente;
  - senão → `update ... where id = p_id`, e se nenhuma linha for afetada, `raise` (cobre o id de outra consultora, que o RLS esconde);
  - `p_endereco` com conteúdo → atualiza o endereço atual ou cria um novo e vincula;
  - `p_endereco` nulo → desvincula e apaga o endereço da cliente.
- Strings vazias viram `null` com `nullif(btrim(...), '')`.
- **Por quê:** cliente e endereço são duas tabelas, e duas chamadas pelo app poderiam deixar um endereço órfão ou uma cliente sem o endereço que a consultora preencheu.

### 3. Migração `..._clientes.sql`
- `clientes`:
  - `check (whatsapp ~ '^[0-9]{10,11}$')`;
  - `check (data_nascimento is null or data_nascimento <= current_date)`.
- `enderecos.uf` já tem o CHECK de formato.
- Índice `clientes (consultora_id, nome)`.
- View e RPC das decisões 1 e 2.
- Antes de aplicar, ajustar `testes.popular` (em `supabase/tests/auxiliares`) para que o WhatsApp tenha só dígitos.

### 4. Camadas no app
| Camada | Arquivo | Responsabilidade |
|---|---|---|
| dto | `core/dto/resumo_cliente_dto.dart` | linha da view |
| dto | `core/dto/cliente_dto.dart`, `core/dto/endereco_dto.dart` | linhas de `clientes` e `enderecos` (leitura dos dados cadastrais) |
| model | `core/model/cliente.dart` | `Cliente` (+ `Endereco?`), `validarNome`, `validarWhatsapp`, `validarNascimento`, `iniciais` |
| model | `core/model/endereco.dart` | `Endereco`, `vazio`, `validar()` (rua e número quando há algo preenchido), `linhaRua`, `linhaBairroCidade` |
| model | `core/model/resumo_cliente.dart` | `ResumoCliente` + `SituacaoCliente` (`atrasada`, `venceHoje`, `aniversario`, `emDia`) calculada com `hoje` injetado; `aniversarianteNoMes`, `comSaldo`, `combinaBusca` (sem acento) |
| model | `core/model/filtro_clientes.dart` | `StatusFiltroCliente`, `OrdemNome` e função pura `filtrar(lista, filtro, busca, ordem, hoje)` |
| service | `core/service/servico_clientes.dart` | `listarResumos`, `buscarResumo(id)`, `buscarCliente(id)` com endereço via `select('*, enderecos(*)')`, `salvar` via `rpc` |
| service | `core/service/servico_cep.dart` | interface + implementação ViaCEP com `http.Client` injetado; timeout de 8 s; `Resultado<EnderecoCep?>` |
| service | `core/service/servico_whatsapp.dart` | interface + implementação com `url_launcher` (`https://wa.me/55<dígitos>`) |
| repository | `core/repository/repositorio_clientes.dart` | cache da lista + `Stream<List<ResumoCliente>>`; após `salvar`, recarrega a lista e emite; `buscarCep` e `abrirWhatsapp` repassam aos serviços |

- Os novos itens são registrados no `injetor`.
- Os erros passam por `mapeador_falhas`.
- O ViaCEP não é Supabase, por isso o `servico_cep` não passa por `core/api`. Ele também não envia nada além do CEP.

### 5. Telas (`ui/modules/clientes/`)
| Pasta | Rota | Observações |
|---|---|---|
| `lista/` | `/clientes` (shell) | `CabecalhoApp` com menu; `CampoSelecaoApp` de status com as contagens; `CampoBuscaApp`; ordem A-Z/Z-A; `BotaoFlutuanteApp` "Novo cliente"; o cubit assina o stream do repositório |
| `formulario/` | `/clientes/novo` e `/clientes/:id/editar` (raiz) | um cubit com `passo` 1 ou 2, os campos e os erros por campo. Continuar valida o passo 1; Salvar valida o endereço e chama o repositório. CEP completo → `buscarCep` → preenche os campos e foca o número. O título é "Novo Cliente" ou "Editar Cliente". O voltar do sistema no passo 2 volta ao passo 1 (`PopScope`) |
| `detalhes/` | `/clientes/:id` (raiz) | `ResumoCliente` vindo do repositório (cache, ou busca pelo id); itens no estilo `GrupoNavegacaoApp`. Compras e Nova venda vão para "em construção" |
| `dados/` | `/clientes/:id/dados` (raiz) | `Cliente` completo; seções com `TituloSecaoApp`; Abrir WhatsApp; Editar → `/clientes/:id/editar` e, na volta, recarrega |

- O widget do card da lista e o selo de situação são específicos de Clientes e ficam em `lista/widgets/`.
- O mapeamento de `SituacaoCliente` para texto, cor e ícone fica nesse widget.

### 6. Abrir WhatsApp
- Usa `url_launcher` com `LaunchMode.externalApplication` e o link `https://wa.me/55<dígitos>`. Se não houver app, o link abre no navegador.
- No iOS, entra `LSApplicationQueriesSchemes` com `https` e `whatsapp`. No Android, o `<queries>` de `VIEW https`.
- Se o `launchUrl` retornar `false`, o app mostra o aviso da spec.

## Risks / Trade-offs

- [O ViaCEP fora do ar ou lento] → timeout curto, aviso e preenchimento manual. O cadastro nunca depende do CEP.
- [Fuso: "hoje" no banco × no aparelho] → a view usa `America/Sao_Paulo`, e o Model recebe `hoje` do relógio local. Para consultoras no Brasil, coincidem. Para outros fusos, haveria divergência de no máximo um dia perto da meia-noite, o que é aceitável no v1.
- [Lista inteira em memória] → é aceitável até alguns milhares de clientes. Se crescer, a busca e o filtro podem ir para a view sem mudar a spec.
- [A view com subconsultas por cliente] → índices existentes em `parcelas (consultora_id, data_vencimento)` e `pagamentos_parcela (parcela_id)`. Ainda falta criar um índice em `vendas (cliente_id)`, se não existir.

## Migration Plan

1. `supabase db reset && supabase test db` local, com os testes novos passando.
2. Aplicar no remoto (`supabase db push`) **só com a confirmação do dono do projeto**.
3. Rollback: uma migração inversa que derruba a view, a função e os CHECKs. Não há perda de dados.
