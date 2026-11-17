---
name: architecture
description: >
  Índice da arquitetura do app Flutter Sou Consultora (core + ui).
  Use ao criar/editar qualquer artefato em lib/ — aponta o skill da camada certa.
---

# Arquitetura — Índice

Leia a rule `.claude/rules/architecture.md` e o skill da camada antes de escrever código.

| Camada / artefato | Skill |
|---|---|
| Abstração Supabase, logs, controle de requests | `core-api` |
| DTO + mapper | `core-dto` |
| Model + lógica reutilizável | `core-model` |
| Service | `core-service` |
| Repository | `core-repository` |
| get_it + env | `core-di-env` |
| Result / AppFailure | `error-handling` |
| Módulo/tela (state, cubit, page) | `ui-module` |
| temas + widgets reutilizáveis | `ui-widgets-themes` |

## Fluxo

```
Screen → Cubit → Repository → Service → Api → Supabase
                      ↓
              DTO ──mapper──► Model → State
```

## Onde vai a lógica?

| Pergunta | Destino |
|---|---|
| Reutilizo em mais de uma tela / pertence ao conceito? | **Model** |
| Só faz sentido nesta tela / fluxo de UI? | **Cubit** |
