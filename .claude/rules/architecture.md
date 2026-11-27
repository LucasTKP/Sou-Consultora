---
paths:
  - "lib/**/*.dart"
---

# Arquitetura — Sou Consultora

## Pastas

| Pasta | Responsabilidade |
|---|---|
| `core/api` | Abstração do client Supabase: logs, limites/controle de requests, helpers comuns |
| `core/dto` | Objeto idêntico à tabela/view. Sem regra de negócio |
| `core/model` | Objeto enriquecido + lógica reutilizável ligada a esse model |
| `core/service` | Consome `api`; monta queries/calls Supabase |
| `core/repository` | Consome `service`; expõe API limpa aos Cubits; DTO→Model via mapper |
| `core/di` | Registro get_it |
| `core/env` | Flavors / URLs / chaves de ambiente |
| `ui/modules/<feature>/<tela>` | `state`, `cubit`, `screen`, `widgets/` opcional. Feature com **uma única tela** não ganha pasta pai: `ui/modules/login/` |
| `ui/navegacao` | `go_router` (`roteador_app`), rotas (`rotas_app`), regra de acesso por sessão (`regras_de_acesso`), `notificador_sessao` e a casca com barra inferior + menu lateral (`casca/`) |
| `ui/formatadores` | Formatadores e máscaras pt-BR (moeda em centavos `int`, data, telefone) |
| `ui/temas` | Temas Material + Shad (`cores_app`, `tema_app`, …) |
| `ui/widgets/<categoria>` | Wrappers shadcn em PT (`botoes`, `formularios`, `cards`, `badges`, `avatares`, …) |

## Idioma

Código nosso em **português** (arquivos, pastas, símbolos, comentários). Exceção: `lib/main.dart` / `main()` e APIs de framework/pacotes. Ver `.claude/rules/dart.md`.

## DTO + mapper

- 1 DTO ↔ 1 formato de banco (linha/tabela).
- Todo DTO tem mapper para o Model correspondente.
- Nullability segue o banco: `NOT NULL` → non-nullable; nullable no banco → nullable no DTO.
- **Proibido** no mapper: `if (json['nome'] == null) throw` para campo obrigatório — o schema já garante.

## Model vs Cubit (onde coloca lógica)

- Reutilizável / pertencente ao conceito do model → **Model**
- Específico de uma tela / fluxo de UI → **Cubit**

## Dependências (direção)

```
ui/modules → repository → service → api
ui/modules → model
repository → dto → model (mapper)
ui nunca importa service/api/dto diretamente (só repository + model)
```

## DI

- get_it como service locator.
- Registrar em `core/di`; Cubit resolve repository via get_it (ou recebe no construtor registrado no get_it).

## Navegação

- Rotas novas entram em `ui/navegacao/roteador_app.dart`; constantes em `RotasApp`.
- **Tela principal** de módulo: dentro do `ShellRoute` (tem barra e menu). Não cria `Scaffold` própria; usa `CabecalhoApp(acao: AcaoCabecalho.menu, onMenu: () => CascaPrincipalScreen.abrirMenu(context))`.
- **Detalhe / formulário**: `GoRoute(parentNavigatorKey: RoteadorApp.chaveRaiz, ...)` — abre por cima, sem barra, com `Scaffold` própria e seta de voltar.
- A navegação por sessão é do roteador (redirect): telas **não** navegam após login/logout.

## Supabase

- App consome Supabase pelo client, **somente** através de `core/api`.
- Proibido espalhar `Supabase.instance.client` em Cubit/Page/Model.
