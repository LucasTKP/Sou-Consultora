# Minha Perfumaria — app_da_consultora

App Flutter da consultora de beleza.

## Stack

- Somente Flutter/Dart
- Supabase (auth/DB) via client oficial, atrás de uma abstração em `core/api`
- Estado: Cubit
- Rotas: go_router (`ui/navegacao/`)
- DI: get_it
- UI kit: **shadcn_ui** (tema em `TemaApp.temaShadClaro`; wrappers PT em `ui/widgets/`)
- Nota: `shadcn_ui` usa `package:flutter/material.dart` (não `material_ui`) — manter alinhado

## Contexto do produto

- Fluxos: `../fluxos.md`
- Banco: `../banco-de-dados.md`
- Telas: `../telas/`

## Arquitetura (obrigatória)

```
lib/
  core/
    api/           # abstração do Supabase (logs, controle de requisições)
    dto/           # espelho do banco + mapper → Model
    model/         # objeto de domínio/UI enriquecido + lógica reutilizável do model
    repository/    # orquestra e consome service
    service/       # chama a api (Supabase abstrato)
    di/            # get_it
    env/           # ambiente / configs
  ui/
    modules/
      <feature>/           # ex.: clientes
        <tela>/            # ex.: lista, novo, detalhes (feature de 1 tela só: sem pasta pai, ex.: login/)
          *_state.dart
          *_cubit.dart
          *_screen.dart
          widgets/         # só widgets específicos daquela tela
    navegacao/             # go_router, rotas, regra de acesso, casca (barra + menu lateral)
    formatadores/          # moeda (centavos int), data, telefone — pt-BR
    temas/                 # ThemeData / tokens do app
    widgets/               # reutilizáveis por categoria
      cards/
      formularios/
      botoes/
      dialog/
```

### Fluxo de dados

`Screen → Cubit → Repository → Service → Api(Supabase) → DTO → mapper → Model → State/UI`

### Idioma

- **Português** em arquivos, pastas, variáveis, classes, métodos e comentários.
- Exceção: `lib/main.dart` + `main()`, APIs Flutter/pacotes, e sufixos `_state` / `_cubit` / `_screen`.

### Regras rápidas

- **DTO** = idêntico ao banco. Campo obrigatório no banco → tipo non-nullable no DTO; **não** revalidar null no mapper.
- **Model** = maior/enriquecido. Lógica **reutilizável** daquele model vive no Model.
- **Cubit** = lógica **bem específica da tela**.
- **core** organizado por **camada** (não por domínio): todos os DTOs em `core/dto/`, etc.
- **UI** por feature (`modules/clientes`) e **uma pasta por tela** dentro do módulo.
- Widgets reutilizáveis só em `ui/widgets/<categoria>/`.
- Telas: `*_state.dart`, `*_cubit.dart`, `*_screen.dart`.
- **Cards de lista** seguem um padrão único (foto 56, nome com a largura toda, 2ª linha com status em cor + detalhes, sem selo): `.claude/rules/cards-lista.md`.

### Erros (padrão do projeto)

- Borda `Service`/`Repository` devolve `Result<T, AppFailure>` (ou equivalente selado).
- Falhas esperadas (rede, auth, not found) → `AppFailure`, não exception crua até a UI.
- Cubit faz `fold`/`switch` e emite estado de erro amigável.
- Exception só para bugs/invariantes quebradas.

Detalhes: `.claude/rules/architecture.md`, `.claude/rules/cards-lista.md` e skills em `.claude/skills/`.

### Segurança (obrigatória, prioridade máxima)

- Cada consultora **só** lê e grava os próprios dados. Nenhum dado é compartilhado ou acessível por `anon`.
- RLS habilitado e forçado em **todas** as tabelas, policies por `auth.uid()`, FKs compostas com `consultora_id`, RPC sem `consultora_id` como parâmetro, Storage privado por pasta do usuário.
- Toda migração traz teste de isolamento (A × B × anon).
- Regras completas: `.claude/rules/seguranca.md`.

## Testes E2E (`integration_test/`)

- App real + Supabase real. Guia completo: `integration_test/README.md`.
- **Suíte inteira só antes de lançar versão** (Play Store / App Store). Durante uma tarefa, rodar **só o cenário dela** (`--plain-name`).
- Toda fase nova acrescenta seu grupo `E2E-0N`, atualiza a tabela de cobertura e o checklist manual do README.
- Antes de rodar: entrar com Google/Apple no app (o `flutter test` desinstala o app no iOS e a sessão se perde).
- Cenários nunca fazem logout e sempre restauram dados alterados (`addTearDown`).

## OpenSpec

- Skills `openspec-*` e comandos `/opsx:*` (propose → apply → sync → archive)
- Config: `openspec/config.yaml` — context/rules **alinhados a esta arquitetura**
- Ao aplicar change, respeitar `architecture.md` (não reintroduzir padrões de monorepo antigo)
- Índice de skills de código: `architecture`
