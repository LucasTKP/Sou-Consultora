# Design

## Context

- `main.dart` abre `AcessoLoginScreen` direto em `home:`. Não há roteador, nem escuta de sessão, nem saída da conta.
- Autenticação existe em `core/api/api_supabase.dart` → `core/service/servico_autenticacao.dart` → `core/repository/repositorio_autenticacao.dart` (Google e Apple via `signInWithIdToken`).
- Widgets já existentes: `BotaoApp` (primário, contorno, secundário, perigo), `CampoTextoApp`, `AreaTextoApp`, `CartaoApp`, `SeloStatusApp`, `AvatarApp`. Os tokens estão em `CoresApp`, `TipografiaApp` e `TemaApp`.
- Referências visuais: `telas/design-system/01-componentes.png`, `telas/inicio/02-menu-lateral.png` e as listas de cada módulo.
- Motivação: `proposal.md`. Comportamento exigido: `specs/`.

## Goals / Non-Goals

**Goals:**
- Um roteador único que concentra o redirecionamento por sessão e as regras de pilha (com ou sem a barra).
- Componentes prontos para que as fases seguintes montem telas só com `ui/widgets/`.

**Non-Goals:**
- Checar se existe registro em `consultoras` e a tela de cadastro do WhatsApp (Fase 1). O roteador já fica com o ponto de extensão para isso.
- Contadores e selos do menu lateral ("2 atrasados", "48 ativas").
- Cache de listas e preservação de rolagem entre abas.

## Decisions

### 1. `go_router` como roteador
- **Por quê:** é o pacote mantido pelo time do Flutter. Ele já traz `redirect` com `refreshListenable` (reage à sessão), `ShellRoute` (barra persistente) e `parentNavigatorKey` (empilhar por cima da barra), com rotas por URL testáveis.
- **Alternativas descartadas:**
  - Navigator 2 manual: muito código próprio.
  - `auto_route`: exige geração de código e acrescenta outro build_runner.

### 2. `ShellRoute` simples, com item ativo calculado pela rota
- As telas principais ficam dentro de um `ShellRoute`, cuja casca desenha a barra e o menu lateral.
- Telas de detalhe e de formulário usam `parentNavigatorKey: chaveRaiz`, então abrem por cima e sem a barra.
- O item ativo vem do primeiro segmento da rota (`/clientes/...` → Clientes). Serviços, Fornecedores, A receber, A pagar e Perfil ficam no shell sem item ativo, como pede a spec.
- **Alternativa descartada:** `StatefulShellRoute`, que exige um ramo por aba e não comporta módulos com barra e sem aba ativa. Ele preservaria o estado das abas, mas o app é online e as listas recarregam rápido.

### 3. Rotas em português, centralizadas em `RotasApp`

| Módulo | Rota principal | Na barra |
|---|---|---|
| Login | `/login` | — (fora do shell) |
| Início | `/inicio` | Início |
| Produtos | `/produtos` | Produtos |
| Clientes | `/clientes` | Clientes |
| Vendas | `/vendas` | Vendas |
| Financeiro | `/financeiro` | Financeiro |
| Serviços | `/servicos` | — |
| Fornecedores | `/fornecedores` | — |
| A receber | `/a-receber` | — |
| A pagar | `/a-pagar` | — |
| Perfil | `/perfil` | — |

Cada fase acrescenta as próprias sub-rotas (ex.: `/clientes/novo`, `/clientes/:id`) com `parentNavigatorKey: chaveRaiz`.

### 4. Sessão: fluxo pelas camadas + regra pura de redirecionamento
- **`core/api/ApiSupabase`** ganha:
  - `Stream<AuthState> get mudancasDeSessao`;
  - `Session? get sessaoAtual`;
  - `Future<void> sair({bool somenteLocal})`.
- **`ServicoAutenticacao.sair()`**:
  - tenta `signOut()` global;
  - em falha de rede, cai para `SignOutScope.local`, como pede a spec ("sair sem internet");
  - depois faz `GoogleSignIn.instance.signOut()`.
- **`RepositorioAutenticacao`** expõe `bool get estaLogado`, `Stream<bool> get sessaoAtiva` e `Future<Resultado<void>> sair()`.
- **`ui/navegacao/notificador_sessao.dart`** (`ChangeNotifier`) assina `sessaoAtiva` e é o `refreshListenable` do roteador.
- **`ui/navegacao/regras_de_acesso.dart`** contém uma função pura: `String? destinoPermitido({required bool logado, required String destino})`.
  - sem sessão e destino ≠ `/login` → `/login`;
  - com sessão e destino = `/login` → `/inicio`;
  - caso contrário → `null`.

  É testada sem Flutter. A Fase 1 acrescenta o parâmetro `temCadastro` → `/cadastro`.
- **Por que `ChangeNotifier` e não Cubit:** o `go_router` exige um `Listenable`. Um Cubit precisaria de um adaptador e não acrescenta nada aqui.

### 5. Pasta nova `ui/navegacao/`
A navegação é transversal e não pertence a nenhuma feature. A estrutura proposta é:

```
ui/navegacao/
  rotas_app.dart              # constantes de rota + item da barra por rota
  roteador_app.dart           # GoRouter, chaves de navegador, redirect
  regras_de_acesso.dart       # função pura de redirecionamento
  notificador_sessao.dart
  casca/
    casca_principal_state.dart
    casca_principal_cubit.dart   # carrega o resumo (nome/foto) e a versão; executa sair()
    casca_principal_screen.dart  # Scaffold com drawer + barra + PopScope
    widgets/
      barra_inferior.dart
      menu_lateral.dart
      item_menu_lateral.dart
```

`architecture.md` e `CLAUDE.md` passam a documentar essa pasta.

### 6. Uma única `Scaffold` na casca
- A casca tem a `Scaffold` com `drawer` e `bottomNavigationBar`. As telas principais **não** criam `Scaffold` própria; elas usam `CabecalhoApp` mais o conteúdo.
- O ícone de menu do `CabecalhoApp` chama `CascaPrincipalScreen.abrirMenu(context)`, que localiza a `ScaffoldState` da casca.
- **Por quê:** `Scaffold` aninhada faria `Scaffold.of(context)` achar a interna, que não tem o drawer.
- Telas empilhadas (detalhe e formulário) têm `Scaffold` própria, com a seta de voltar.

### 7. Botão voltar
- O `PopScope` da casca segue esta lógica:
  - rota ≠ `/inicio` → `context.go('/inicio')`;
  - em `/inicio` → permite o pop, e o app fecha.
- O drawer aberto e as folhas inferiores já fecham primeiro pelo comportamento padrão do Flutter.
- Telas empilhadas ficam no navegador raiz e são desempilhadas antes de a casca ser consultada.

### 8. Cabeçalho do menu: resumo vindo do login, por enquanto
- `RepositorioAutenticacao.resumoDaConsultora()` devolve o model `ResumoConsultora (nome, fotoUrl, iniciais)`, novo em `core/model/`, montado com `full_name`/`avatar_url` dos metadados do Google ou da Apple.
- Na Fase 1, a fonte passa a ser a tabela `consultoras`, sem mudar o model nem a tela.
- As iniciais ficam no model, porque são lógica reutilizável por avatar, card de cliente e menu.

### 9. Módulos em construção
- O widget `EstadoEmConstrucaoApp` (em `ui/widgets/estados/`) recebe o título e é usado pelas rotas ainda sem tela.
- Cada fase substitui o builder da sua rota pela tela real.

### 10. Componentes reutilizáveis
Todos são wrappers de `shadcn_ui` quando existe a base equivalente, com nomes e parâmetros em português.

| Componente | Pasta | Referência visual |
|---|---|---|
| `CabecalhoApp` (vinho com borda inferior arredondada; ação esquerda menu ou voltar; título; subtítulo opcional "PASSO 1 DE 2"; ação direita opcional) | `estrutura/` | todas as telas |
| `CampoTextoApp` (+ rótulo sobre a borda, marcação `*` ou "(Opcional)", mensagem de erro) | `formularios/` | DS "Inputs" |
| `CampoSelecaoApp<T>` (lista com busca opcional e botão de atalho `>` ao lado) | `formularios/` | Nova venda, Novo boleto |
| `CampoMoedaApp` (R$, máscara pt-BR, devolve centavos `int`) | `formularios/` | "Valor da mensalidade" |
| `CampoDataApp` (abre o calendário pt-BR e mostra dd/MM/aaaa) | `formularios/` | Novo boleto |
| `CampoBuscaApp` | `formularios/` | listas |
| `SeletorQuantidadeApp` (− n +, mínimo e máximo) | `formularios/` | Adicionar item, Lançar estoque |
| `AlternadorSegmentadoApp<T>` (Produto \| Serviço; Entradas \| Saídas) | `formularios/` | Adicionar item, Estoque |
| `BotaoFlutuanteApp` (estendido, "+ Novo cliente") | `botoes/` | listas |
| `BotaoIconeApp` (quadrado com chevron ou ícone) | `botoes/` | ao lado de seleções |
| `CartaoListaApp` (avatar ou foto, título, subtítulo, selo, chevron, toque) | `cards/` | "Cards & Linhas" |
| `GrupoNavegacaoApp` + `ItemNavegacaoApp` (ícone em quadrado colorido, título, descrição, chevron) | `cards/` | "Padrão Detalhes do Cliente" |
| `FotoQuadradaApp` (1:1, `cover`, tamanhos destaque 80, card 56 e miniatura 40, fallback de ícone) | `avatares/` | "Padrão de Fotos" |
| `FolhaInferiorApp.mostrar(...)` (alça, título, subtítulo, fechar, conteúdo, ações) | `dialog/` | folhas de opções |
| `DialogoConfirmacaoApp.mostrar(...)` (variante perigo para ações destrutivas) | `dialog/` | Sair, Cancelar venda |
| `IndicadorPassosApp` ("Passo 1 de 2" + barra de progresso) | `indicadores/` | Novo boleto |
| `EstadoVazioApp`, `EstadoCarregandoApp`, `EstadoErroApp` (com "Tentar novamente"), `EstadoEmConstrucaoApp` | `estados/` | — |

`CampoMoedaApp` trabalha com **centavos inteiros (`int`)**, sem `double` em dinheiro. A conversão para o `numeric` do banco fica no mapper do DTO.

### 11. Formatadores em `ui/formatadores/`
- `FormatadorMoeda`: `formatar(int centavos)` → "R$ 1.234,56" e `ler(String)` → centavos.
- `FormatadorData`: "15/05/2024", "15 de outubro de 2024" e "há 18 dias".
- `FormatadorTelefone`: "(11) 98765-4321".
- `TextInputFormatter`s correspondentes: `MascaraMoeda`, `MascaraTelefone`, `MascaraData`.
- Usam `intl` com `pt_BR`. `main.dart` chama `initializeDateFormatting('pt_BR')`.
- **Por que em `ui/`:** é apresentação. Regras de negócio com datas (atraso, recompra) ficam nos Models.

### 12. Login permanece em `ui/modules/login/`
- Decisão do dono do projeto: feature com uma única tela não ganha pasta pai. O mesmo vale para o cadastro do WhatsApp (Fase 1, `ui/modules/cadastro/`).
- A navegação pós-login deixa de ser responsabilidade da tela: o redirecionamento reage à sessão.

## Risks / Trade-offs

- **[Listas recarregam ao trocar de aba]** → Aceitável num app só online. Se incomodar, migrar para `StatefulShellRoute` só nas 5 abas.
- **[Metadados do Google sem nome ou foto, por exemplo Apple sem compartilhar o nome]** → O model cai para o e-mail e as iniciais "?". A Fase 1 resolve com o cadastro próprio.
- **[`signOut` global falha offline]** → Fallback `SignOutScope.local`: a sessão do aparelho é removida mesmo assim, e o token remoto expira sozinho.
- **[Dependências novas]** → Pacotes estáveis e mantidos. Versões fixadas com `^` no `pubspec.yaml`.
