---
name: error-handling
description: >
  Padrão de erros do app: Result + AppFailure selado na borda Service/Repository;
  Cubit traduz para estado de UI. Use ao tratar falhas de rede/auth/dados.
---

# Erros — Result + AppFailure

## Recomendação adotada

Na borda **Service/Repository**:

```dart
sealed class AppFailure {
  const AppFailure(this.message);
  final String message;
}

final class NetworkFailure extends AppFailure { ... }
final class AuthFailure extends AppFailure { ... }
final class NotFoundFailure extends AppFailure { ... }
final class UnexpectedFailure extends AppFailure { ... }

typedef Result<T> = /* Ok<T> | Err<AppFailure> */; // sealed próprio ou pacote (result_dart, etc.)
```

## Regras

1. Falhas **esperadas** (offline, 401, row missing) → `AppFailure` dentro de `Result`
2. Cubit: `switch`/`fold` no Result → emite `loading` / `loaded` / `error` no State
3. **Não** deixe `PostgrestException` chegar na Page
4. Mensagem ao usuário: útil e em PT-BR; sem stacktrace
5. `throw` só para bug/invariante impossível (assert de programador)

## Por que não Exception em tudo?

- Força o Cubit a tratar caminhos de erro
- Evita try/catch genérico engolindo bugs
- Combina bem com states selados da UI
