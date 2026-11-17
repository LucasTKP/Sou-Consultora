---
name: core-repository
description: >
  Repositories em core/repository — consomem service, aplicam mapper DTO→Model, API limpa ao Cubit.
---

# core/repository

## Responsabilidade

Fachada para a UI (Cubits). Consome `Service`, aplica mapper DTO→Model, devolve `Model` / `Result`.

## Regras

- Cubit fala com **Repository**, não com Service/Api/DTO
- Converte DTO→Model via mapper do DTO
- Pode orquestrar 2+ services se necessário
- Sem `BuildContext`, sem widget
- Pasta: `lib/core/repository/`

## Assinatura típica

```dart
Future<Result<List<ClienteModel>, AppFailure>> listar();
Future<Result<ClienteModel, AppFailure>> salvar(ClienteModel cliente);
```
