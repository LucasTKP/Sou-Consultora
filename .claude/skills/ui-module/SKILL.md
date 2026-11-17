---
name: ui-module
description: >
  Módulos de UI: ui/modules/<feature>/<tela> com state, cubit, screen e widgets locais.
  Use ao criar ou alterar telas do app.
---

# ui/modules — Feature + tela

## Estrutura

```
ui/modules/<feature>/<tela>/
  <feature>_<tela>_state.dart
  <feature>_<tela>_cubit.dart
  <feature>_<tela>_screen.dart
  widgets/                    # opcional — só desta tela
```

Nomes de arquivos/símbolos/comentários em **português**, com exceção de `main.dart`, APIs Flutter/pacotes e sufixos `_state` / `_cubit` / `_screen`.

Exemplo:

```
ui/modules/clientes/
  lista/
    clientes_lista_state.dart
    clientes_lista_cubit.dart
    clientes_lista_screen.dart
    widgets/
  novo/
    ...
  detalhes/
    ...
```

## State

- Selado / imutável: `Inicial`, `Carregando`, `Carregado`, `Erro` (e variantes da tela)
- Guarda **Models**, não DTOs

## Cubit

- Fala só com **Repository** (+ Model)
- Lógica **específica da tela** (formulário local, passos do wizard, etc.)
- Lógica reutilizável do conceito → empurre para o **Model**
- Sem Supabase/Api/Service direto

## Screen

- Renderiza State; dispara métodos do Cubit
- Widgets genéricos de `ui/widgets/...`
- Widgets só desta tela em `./widgets/`

## Dependências

```
Screen → Cubit → Repository → …
           ↘ Model
```
