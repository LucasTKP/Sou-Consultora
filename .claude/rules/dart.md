---
paths:
  - "**/*.dart"
---

# Regras Dart — Sou Consultora

Guardrails em todo arquivo `.dart`. Arquitetura detalhada em `.claude/rules/architecture.md`.

## Imutabilidade

- Campos `final`; `const` quando possível.
- Atualizar com `copyWith` (não mutar).
- Nullable no `copyWith` → `ValueGetter<T?>?` quando precisar distinguir "não mexer" vs `null`.

## Estrutura

- Máx **1 nível** de indentação por método — extraia privados.
- Early return; evite `else if` em cadeia.
- Callbacks de UI apontam para método nomeado (`_onSalvar`), sem corpo grande inline.
- Um método, uma responsabilidade.

## Camadas (resumo)

- Page: só UI e disparo de eventos do Cubit.
- Cubit: orquestra a tela; lógica só se for específica da tela.
- Repository: API limpa para o Cubit; usa Service + mapper DTO→Model.
- Service: fala com `core/api` (Supabase).
- Api: única porta para o client Supabase (logs / controle de requests).
- DTO: espelho do banco + mapper.
- Model: dados enriquecidos + lógica reutilizável do conceito.

## Erros

- Borda Service/Repository: `Result<T, AppFailure>` (selado).
- Cubit traduz failure → estado de erro (mensagem útil).
- Sem `print` de debug em produção; use o logger da `api`/utilitário do app.
- Nunca mostre stacktrace ao usuário.

## Validação de formulários

- Regras no **Model** (reutilizáveis, ex.: telefone válido) e orquestração no **Cubit** (`salvar()` valida e emite estado com o erro de cada campo).
- A tela só repassa: `CampoTextoApp(erro: estado.erroNome)`. Nada de regra em `validator` de `Form` por padrão.
- Erros do servidor (ex.: nome duplicado) chegam pelo mesmo caminho do estado.

## UI

- Widgets reutilizáveis em `ui/widgets/<categoria>/`.
- Widget só da tela → `ui/modules/<feature>/<tela>/widgets/`.
- Tratar loading / erro / vazio no state.
- `BuildContext` após `await` só com `mounted` / `context.mounted`.
- Sem efeito colateral em `build`.
- Controllers/subscriptions com `dispose`/`cancel`.

## Idioma — português em tudo (código nosso)

**Tudo que nós escrevemos é em português (pt-BR):** nomes de **arquivos**, **pastas**, **classes**, **variáveis**, **métodos**, **enums**, **comentários** e textos de UI.

### Única exceção de arquivo de entrada

- O arquivo **`lib/main.dart`** e a função **`main()`** permanecem assim (exigência do Flutter).

### O que NÃO traduzir (API externa / sufixos de tela)

- APIs do Flutter/Dart e de pacotes (`Widget`, `BuildContext`, `setState`, parâmetros de `ColorScheme`, etc.).
- Nomes de pacotes pub (`flutter_bloc`, `get_it`, `supabase_flutter`).
- Sufixos de arquivo/tipo de tela em **inglês**: `_state`, `_cubit`, `_screen` (e tipos `State` / `Cubit` / `Screen`).

### Arquivos de tela

- `<feature>_<tela>_state.dart`
- `<feature>_<tela>_cubit.dart`
- `<feature>_<tela>_screen.dart`  
  Ex.: `clientes_lista_screen.dart`

### Exemplos

```dart
// ✅
final nomeCliente = cliente.nome;
class CoresApp { static const primaria = Color(0xFFB0396F); }
/// Tokens de cor do design system.

// ❌
final customerName = customer.name;
class AppColors { static const primary = ...; }
/// Color tokens from the design system.
```

## Comentários

- Comentários e docs (`///` / `//`) **sempre em português**.
- `///` em APIs públicas quando a assinatura não basta.
- `//` só para o atípico (workaround, quirk).
- Sem código comentado nem TODO órfão.
