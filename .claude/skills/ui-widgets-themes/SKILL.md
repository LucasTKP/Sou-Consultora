---
name: ui-widgets-themes
description: >
  ui/temas e ui/widgets reutilizáveis organizados por categoria (cards, formularios, botoes, dialog...).
  Nomes em português (cores_app, TemaApp, etc.).
---

# temas + widgets reutilizáveis

## temas/

- `CoresApp`, `TemaApp.claro`, `TemaApp.temaShadClaro` (shadcn_ui)
- App sobe com `ShadApp.custom` + `MaterialApp` + `ShadAppBuilder` (ver `main.dart`)
- Arquivos/símbolos em português
- Sem regra de negócio

## shadcn_ui

Usar **wrappers em português** em `ui/widgets/`, não `Shad*` direto nas pages:

| Wrapper | Base | Pasta | Uso |
|---|---|---|---|
| `BotaoApp` (`.contorno`, `.secundario`, `.perigo`) | `ShadButton` | `botoes/` | ações principais |
| `BotaoFlutuanteApp` | `FloatingActionButton.extended` | `botoes/` | "+ Novo cliente" nas listas |
| `BotaoIconeApp` | `Material` + `InkWell` | `botoes/` | atalho ">" ao lado de seleções |
| `CampoTextoApp` (rótulo sobre a borda, `obrigatorio` → " *", `opcional` → " (Opcional)", `erro`) | `TextField` | `formularios/` | todo campo de texto |
| `AreaTextoApp` | `CampoTextoApp` | `formularios/` | observações |
| `CampoBuscaApp` | `CampoTextoApp` | `formularios/` | busca das listas |
| `CampoMoedaApp` (devolve **centavos `int`**) | `CampoTextoApp` + `MascaraMoeda` | `formularios/` | valores em R$ |
| `CampoDataApp` (calendário pt-BR) | `CampoTextoApp` + `showDatePicker` | `formularios/` | datas |
| `CampoSelecaoApp<T>` (busca e atalho opcionais) | `CampoTextoApp` + `FolhaInferiorApp` | `formularios/` | cliente, fornecedor, produto… |
| `SeletorQuantidadeApp` (mín./máx.) | `Container` + `IconButton` | `formularios/` | quantidade |
| `AlternadorSegmentadoApp<T>` + `OpcaoSegmento` | `Material` + `InkWell` | `formularios/` | Produto \| Serviço |
| `CartaoApp` | `ShadCard` | `cards/` | card genérico |
| `CartaoListaApp` | `Material` + `InkWell` | `cards/` | linhas das listas |
| `GrupoNavegacaoApp` + `ItemNavegacaoApp` | `Material` | `cards/` | "Dados cadastrais / Compras / Extrato" |
| `SeloStatusApp` + `StatusSelo` | `ShadBadge` | `badges/` | Quitado / A receber / Atrasado |
| `AvatarApp` + `TamanhoAvatar` (foto ou iniciais) | `ShadAvatar` | `avatares/` | pessoas |
| `FotoQuadradaApp` (1:1, `cover`, reserva) | `Image.network` | `avatares/` | produtos e serviços |
| `CabecalhoApp` + `AcaoCabecalho` (menu / voltar / nenhuma) | `Material` | `estrutura/` | topo de toda tela |
| `IndicadorPassosApp` | `LinearProgressIndicator` | `indicadores/` | "Passo 1 de 2" |
| `FolhaInferiorApp.mostrar<T>` | `showModalBottomSheet` | `dialog/` | folhas de opções |
| `DialogoConfirmacaoApp.mostrar` → `bool` | `AlertDialog` | `dialog/` | confirmar ações (perigo) |
| `EstadoVazioApp`, `EstadoCarregandoApp`, `EstadoErroApp`, `EstadoEmConstrucaoApp` | — | `estados/` | estados de tela |

Os campos de texto usam `TextField` (e não `ShadInput`) porque o design pede o rótulo sobre a borda, que o `ShadInput` não oferece.

Formatadores pt-BR em `ui/formatadores/`: `FormatadorMoeda` (centavos ↔ "R$ 1.234,56"), `FormatadorData`, `FormatadorTelefone` e as máscaras `MascaraMoeda`, `MascaraData`, `MascaraTelefone`. **Dinheiro é sempre `int` em centavos.**

Cores do DS via `CoresApp` / `TemaApp.esquemaShadClaro`. Status de badge: `StatusSelo`.

## widgets/

Sempre por **categoria**:

```
ui/widgets/
  cards/
  formularios/
  botoes/
  badges/
  avatares/
  dialog/
  estrutura/
  indicadores/
  estados/
```

## Regras

- Card de lista: sempre `CartaoListaApp` + `LinhaSituacaoApp` (ver `.claude/rules/cards-lista.md`)
- Reutilizável em 2+ telas → `ui/widgets/<categoria>/`
- Só uma tela usa → `ui/modules/<feature>/<tela>/widgets/`
- Preferir wrappers `*App`; só use `Shad*` cru se ainda não houver wrapper
- Widgets burros: dados/callbacks; sem Repository
