---
name: core-api
description: >
  Abstração do client Supabase em core/api — logs, controle de quantidade/concorrência
  de requisições e helpers HTTP/PostgREST. Use ao criar ou alterar a porta de acesso ao Supabase.
---

# core/api — Abstração Supabase

## Responsabilidade

Única camada autorizada a falar com o client Supabase (`SupabaseClient`).

Cubit, Page, Model, DTO e Repository **não** importam `supabase_flutter` diretamente.

## O que colocar aqui

- Wrapper/facade sobre `SupabaseClient`
- Logging de request/response (sem PII sensível demais)
- Controle de requisições (fila, debounce, limite de concorrência, cancelamento)
- Helpers comuns (timeout, headers, tratamento bruto de `PostgrestException`)
- Acesso a Auth / Realtime encapsulado, se necessário

## O que NÃO colocar

- Regra de negócio
- Mapeamento DTO↔Model
- Estado de UI

## Direção

`Service` → `Api` → Supabase client

Service recebe a abstração via get_it, nunca o client cru.
