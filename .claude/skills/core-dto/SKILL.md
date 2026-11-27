---
name: core-dto
description: >
  DTOs em core/dto — espelho do banco Supabase e mapper para Model.
  Use ao criar/editar tabelas espelhadas ou conversão banco→domínio.
---

# core/dto

## Responsabilidade

Objeto **idêntico** ao formato do banco (linha da tabela/view). Sem regra de negócio.

Todo DTO tem **mapper** para o Model correspondente.

## Nullability = schema

| Banco | DTO |
|---|---|
| `NOT NULL` | tipo non-nullable |
| nullable | tipo nullable |

No mapper de campo obrigatório: **não** valide "veio ou não" — o banco já define. Confie no tipo.

## Mapper

- Preferência: métodos no DTO (`toModel()` / `fromMap` + `toModel`) ou mapper dedicado ao lado do DTO.
- `fromMap`/`fromJson` só hidrata o DTO; conversão rica fica no passo → Model.
- Datas, enums e UUIDs: parse explícito e tipado.

## Pasta

Tudo em `lib/core/dto/` (organização por camada, não por feature).
