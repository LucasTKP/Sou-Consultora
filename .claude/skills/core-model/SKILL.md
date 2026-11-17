---
name: core-model
description: >
  Models em core/model — objetos enriquecidos e lógica reutilizável do conceito.
  Use ao criar/editar models ou ao decidir se lógica vai no Model ou no Cubit.
---

# core/model

## Responsabilidade

Objeto **maior** que o banco: agrega, deriva, formata e encapsula comportamento
reutilizável daquele conceito (ex.: cliente com saldo, venda com totais).

## Lógica no Model vs Cubit

| Coloque no Model | Coloque no Cubit |
|---|---|
| Cálculo/derivação reutilizável | Sequência só daquela tela |
| Invariante do conceito | Navegação, dialogs, toasts |
| Formatação/domínio do dado | Campos temporários de formulário |

## Regras

- Imutável (`final` + `copyWith`)
- Não fala com Supabase, Api, Service nem Repository
- Não depende de `BuildContext`
- Pasta: `lib/core/model/`
