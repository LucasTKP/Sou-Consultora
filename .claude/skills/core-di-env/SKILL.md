---
name: core-di-env
description: >
  get_it em core/di e configs de ambiente em core/env. Use ao registrar deps ou ler env.
---

# core/di + core/env

## DI (get_it)

- Registrar `Api`, `Service`s, `Repository`s e `Cubit`s (se aplicável) em `core/di`
- Preferir construtor explícito + registro no get_it
- LazySingleton para Api/Services/Repositories; Factory para Cubits com estado por tela

## Env

- URLs, anon key, flavor (`dev`/`prod`) em `core/env`
- Nada de secret de service_role no app cliente
- Não hardcode keys em widgets/cubits
