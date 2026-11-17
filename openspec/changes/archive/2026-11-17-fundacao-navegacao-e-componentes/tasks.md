# Tasks

## 1. Dependências e estrutura

- [x] 1.1 Adicionar `go_router`, `intl` e `package_info_plus` ao `pubspec.yaml` e verificar com `flutter pub get` sem conflitos

## 2. Sessão nas camadas core

- [x] 2.1 Em `core/api/api_supabase.dart`, expor `mudancasDeSessao`, `sessaoAtual` e `sair({somenteLocal})`; verificar com `flutter analyze`
- [x] 2.2 Em `core/service/servico_autenticacao.dart`, criar `sair()` (global, com fallback local em falha de rede, depois `GoogleSignIn.signOut()`) retornando `Resultado<void>`; verificar com teste unitário em `test/core/service/` cobrindo sucesso e fallback offline
- [x] 2.3 Criar o model `core/model/resumo_consultora.dart` (nome, fotoUrl, iniciais, com fallback para e-mail e "?"); verificar com teste unitário das iniciais
- [x] 2.4 Em `core/repository/repositorio_autenticacao.dart`, expor `estaLogado`, `sessaoAtiva`, `sair()` e `resumoDaConsultora()`; verificar com teste unitário usando service falso

## 3. Formatadores

- [x] 3.1 Criar `ui/formatadores/` (`FormatadorMoeda`, `FormatadorData`, `FormatadorTelefone`) e as máscaras `MascaraMoeda`, `MascaraTelefone`, `MascaraData`; chamar `initializeDateFormatting('pt_BR')` no `main.dart`; verificar com testes unitários em `test/ui/formatadores/` (ida e volta de centavos, datas por extenso, "há N dias", máscara de telefone com 10 e 11 dígitos)

## 4. Componentes do design system

- [x] 4.1 Criar `estrutura/CabecalhoApp` e `indicadores/IndicadorPassosApp`; verificar com widget test (título, subtítulo, ação de voltar e de menu, progresso)
- [x] 4.2 Ampliar `CampoTextoApp` (rótulo, obrigatório ou opcional, erro) e criar `CampoBuscaApp`, `CampoMoedaApp`, `CampoDataApp`; verificar com widget test (rótulo exibido, erro exibido, moeda devolve centavos)
- [x] 4.3 Criar `CampoSelecaoApp<T>`, `SeletorQuantidadeApp` e `AlternadorSegmentadoApp<T>`; verificar com widget test (seleção devolve valor, quantidade respeita mínimo e máximo, alternador troca o valor)
- [x] 4.4 Criar `BotaoFlutuanteApp` e `BotaoIconeApp`; verificar com widget test de toque
- [x] 4.5 Criar `CartaoListaApp`, `GrupoNavegacaoApp` / `ItemNavegacaoApp` e `FotoQuadradaApp`; verificar com widget test (toque, selo, fallback de foto, proporção 1:1)
- [x] 4.6 Criar `FolhaInferiorApp.mostrar` e `DialogoConfirmacaoApp.mostrar`; verificar com widget test (abre, fecha, confirma devolve `true`, cancela devolve `false`)
- [x] 4.7 Criar `EstadoVazioApp`, `EstadoCarregandoApp`, `EstadoErroApp` e `EstadoEmConstrucaoApp`; verificar com widget test ("Tentar novamente" chama o callback)
- [x] 4.8 Atualizar `.claude/skills/ui-widgets-themes/SKILL.md` com a tabela dos novos wrappers; verificar que todo widget criado está listado

## 5. Navegação

- [x] 5.1 Criar `ui/navegacao/regras_de_acesso.dart` com `destinoPermitido`; verificar com teste unitário dos cenários de `specs/controle-de-acesso` (sem sessão → login; com sessão em login → início; demais → livre)
- [x] 5.2 Criar `rotas_app.dart` (constantes e item da barra por rota) e `notificador_sessao.dart`; verificar com teste unitário do mapeamento rota → item ativo (inclusive módulos sem item)
- [x] 5.3 Criar `roteador_app.dart` (`GoRouter`, chave raiz, `ShellRoute`, `redirect`, `refreshListenable`, rotas dos 10 módulos com `EstadoEmConstrucaoApp` e `/login`); verificar com `flutter analyze`
- [x] 5.4 Criar a casca (`casca_principal_state/cubit/screen`) com `BarraInferior` (5 itens, Início central) e `PopScope`; verificar com widget test (ordem dos itens, item ativo, trocar de aba, voltar fora do Início vai ao Início)
- [x] 5.5 Criar `MenuLateral` (cabeçalho com foto ou iniciais, Ver perfil, grupos, item atual destacado, Configurações, Sair com `DialogoConfirmacaoApp`, versão); verificar com widget test (navega e fecha, destaque, sair confirmado chama o repositório, sair cancelado não chama)
- [x] 5.6 Ligar o roteador no `main.dart` (`MaterialApp.router`) e remover a navegação manual do login; verificar com widget test de ponta a ponta usando repositório falso (sem sessão → login; ao logar → início; ao sair → login sem voltar)

## 6. Documentação e verificação final

- [x] 6.1 Documentar `ui/navegacao/` e `ui/formatadores/` em `.claude/rules/architecture.md` e `.claude/CLAUDE.md`, e registrar a barra inferior fixa em `../fluxos.md`; verificar que os três documentos estão consistentes
- [x] 6.2 Rodar `flutter analyze` e `flutter test` e verificar zero problemas e todos os testes passando
- [ ] 6.3 Rodar o app no simulador, entrar com Google e percorrer barra, menu, voltar e sair; registrar o resultado
  - 17/11: build iOS (simulador iPhone 16 Pro Max) ok; com sessão salva o app abriu direto no Início, com cabeçalho, barra fixa e Início em destaque. **Falta o percurso manual** (menu, trocar de aba, voltar, sair e entrar de novo com Google), a ser feito pelo dono do projeto.

## Resultado

- `flutter test`: **64 testes passando** (core 11, formatadores 10, widgets 19, navegação 24).
- `flutter analyze`: só o aviso de depreciação já existente em `ui/temas/tipografia_app.dart`.
- Correções encontradas pelos testes:
  - `AvatarApp` sem foto não mostrava as iniciais (`src` vazio em vez de nulo);
  - o rótulo dos botões de login estourava em tela estreita ou com fonte grande.
- `test/widget_test.dart` estava desatualizado (procurava o texto "Sou Consultora", que não existe no login) e foi substituído pelo teste de navegação, que confere logo, frase e botões.

## Workflow follow-up

- Arquivar a change com `/opsx:archive` depois da revisão.
