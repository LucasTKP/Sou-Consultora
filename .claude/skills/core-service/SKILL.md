---
name: core-service
description: >
  Services em core/service — consomem core/api (Supabase abstrato) e devolvem DTOs/Result.
  Use ao criar/editar chamadas de dados.
---

# core/service

## Responsabilidade

Executar operações de dados via `core/api`. Traduz intenção ("listar clientes da consultora")
em calls Supabase.

## Regras

- Depende só de `Api` (abstração), não do client cru
- Devolve `DTO` ou `Result<DTO, AppFailure>` / listas tipadas
- Sem regra de UI; sem `BuildContext`
- Sem mapear para Model (isso é do Repository + mapper do DTO)
- Pasta: `lib/core/service/`

## Erros

Capture falhas esperadas do Supabase e mapeie para `AppFailure`. Não deixe exception crua subir até o Cubit.
