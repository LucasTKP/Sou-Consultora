---
name: "RELEASE"
description: Gera versão de um ou mais apps do front — pergunta quais apps e o bump de cada um, escreve as notas, e publica (commit + tag) disparando o deploy de produção
category: Release
tags: [release, deploy, front-core, tag, versão]
---

Publica versão de produção de um ou mais apps do `front-core`. Cada app tem **sua própria versão e sua própria tag** (`<app>-v<X.Y.Z>`), mas **a release é uma só**: um commit com todos os bumps, N tags, e um run do workflow **Release [PROD]** — que roda o gate `analyze` + `test-all` uma vez para o conjunto e publica os apps em paralelo. Mecanismo completo: `@README.md`.

Tudo roda a partir de `front-core/` — o alvo `release` é do makefile dele, não do da raiz.

**Input**: `$ARGUMENTS` = opcional. Nomes de apps (`/release pdv console`) e/ou bump (`/release pdv --patch`). O que não vier no argumento, **você pergunta** com `AskUserQuestion`.

> 🚦 **Publicar é irreversível**: as tags vão pro origin e o deploy de produção começa sozinho. Voltar atrás exige outra versão. O gate humano do passo 5 é obrigatório — sem OK explícito, não publique.

## 1. Pré-voo

```bash
cd front-core
git fetch origin main --tags
git branch --show-current                      # → main
git status --porcelain                         # → vazio
git rev-list --count HEAD..origin/main         # → 0 (não está atrás)
git rev-list --count origin/main..HEAD         # → 0 (nada local não pushado)
```

Os quatro são exigência do script, não zelo:

- **Fora da `main`** → `release sai da main`. Se a branch atual já estiver mergeada (`git diff --stat origin/main HEAD` vazio), proponha `git checkout main && git pull --ff-only`. Com diff, **pare**: tem trabalho não mergeado e a tag sairia sem ele.
- **Árvore suja** → `_assertTreeMatchesTag` recusa. Faz sentido: o gate roda no working tree, mas a tag sai do HEAD; verde aqui e vermelho na CI com a tag já publicada.
- **Atrás do origin** → `git pull --ff-only origin main`.
- **Commit local não pushado** → `_assertPublishable` recusa qualquer arquivo que difira entre `origin/main` e `HEAD` fora do bump: `push HEAD:main` levaria isso pra produção de carona. Suba por PR antes.

## 2. Perguntar QUAIS APPS (`AskUserQuestion`, `multiSelect: true`)

Pule se o usuário já nomeou os apps em `$ARGUMENTS`.

- `question`: "Quais apps entram no release?" · `header`: "Apps" · `multiSelect: true`

| label | description |
|---|---|
| `pdv` | PDV — Play Store + Microsoft Store |
| `console` | Console — painel web do estabelecimento |
| `app` | App do cliente — Play Store |
| `waiter` | Garçom — Play Store (`com.paipfood.waiter`) |

O tool aceita no máximo 4 opções — esses quatro são os que têm deploy de produção montado; `admin`, `portal` e `landing_page` entram pelo "Other". Aceitos pelo script: `admin`, `app`, `console`, `pdv`, `portal`, `landing_page`, `waiter`; qualquer outro nome o script rejeita.

## 3. Perguntar o BUMP DE CADA APP (`AskUserQuestion`, uma pergunta por app)

Leia a versão atual de cada app escolhido **antes** de perguntar — é dela que sai o exemplo:

```bash
grep -m1 '^version:' apps/<app>/pubspec.yaml         # Flutter: X.Y.Z+B
grep -m1 '"version"' apps/landing_page/package.json  # landing_page: semver puro
```

Uma pergunta por app (até 4 por chamada; com 5+ apps, duas chamadas), `multiSelect: false`, `header` = nome do app. **Calcule os números reais** — é isso que deixa o usuário ver no que vai dar antes de escolher:

> `question`: "pdv está em 1.0.2+13. Qual bump?"

| label | description (com a versão real) |
|---|---|
| `patch` | `1.0.2+13 → 1.0.3+14` — correção, ajuste, nada novo pro usuário |
| `minor` | `1.0.2+13 → 1.1.0+14` — funcionalidade nova, compatível |
| `major` | `1.0.2+13 → 2.0.0+14` — quebra de comportamento |

O `+B` **sempre soma 1**, seja qual for o bump: é o `versionCode` da Play, que recusa upload repetido. O `landing_page` não tem `+B` (versiona pelo `package.json`).

**Versão fora do bump** (o usuário responde no "Other", ex.: "quero 1.0.3 e não 1.1.0"): rode o `make release` com o bump mais próximo e depois edite **os dois** lugares — a linha `version:` do `pubspec.yaml` e a **1ª linha** do `release_notes.txt` (`<app> <X.Y.Z>`), que o script semeia com o número antigo e vira a mensagem da tag. Na publicação o `_assertOnlyVersionChanged` compara o arquivo com `origin/main` e só tolera a linha de versão mexida — editar à mão passa, encostar em dependência não.

## 4. Bumpar e escrever as notas

Para cada app escolhido (`make release` **não commita** — só mexe no working tree):

```bash
make release APP=<app> BUMP=<patch|minor|major>
```

Se o `pubspec.yaml` ou o `release_notes.txt` daquele app já estiverem sujos, o script recusa (re-preparar apagaria a edição). Para re-semear por cima, o Makefile não expõe a flag — chame o script direto:

```bash
dart scripts/release.dart <app> --bump <patch|minor|major> --force
```

**As notas semeadas são rascunho de `git log`**: saem com todos os commits do período — quase sempre só a linha do squash da PR —, não com o que o usuário do app vê. **Reescreva**, preservando a 1ª linha `<app> <X.Y.Z>`:

```bash
git log --oneline <app>-v<última>..HEAD    # o que entrou
git diff --stat <app>-v<última>..HEAD      # onde mexeu
```

PT-BR, do ponto de vista de quem usa o app — é a mensagem da tag. Cada app recebe só a nota do que muda **nele**: uma feature compartilhada se descreve diferente no app que a usa e no que a configura.

> As notas editadas **não** chegam aos testers do Firebase: as CIs de staging do `app` e do `pdv` regeram o arquivo do `git log` antes de distribuir.

## 5. Gate humano — pare e espere o OK

Apresente:

- versão antiga → nova de cada app, e a tag que vai nascer;
- o texto **completo** das notas de cada app;
- `git status --short`.

**Espere o OK explícito.** Sem isso, não siga.

## 6. Publicar — todos os apps num comando

```bash
SKIP_GATE=1 make release-publish APP=<a>,<b>,<c>
```

Um comando para a release inteira: **um** commit com todos os bumps (`:bookmark: feat(release): Versão app 1.2.3+45, portal 0.4.1`), uma tag anotada por app, e um `gh workflow run release.yml` com os apps marcados. Nada de stash, nada de publicar um por vez — a árvore só precisa estar limpa **fora dos bumps desta release**, e todos eles estão nela.

**`SKIP_GATE=1` é o padrão aqui**: analyze e testes são da CI, que roda o job `quality` antes de buildar qualquer coisa; o gate local duplica isso e custa ~15 min (ele ainda roda `flutter pub upgrade` antes, pra reproduzir a resolução da CI). `_assertTreeMatchesTag` **continua valendo** — ele vive no `_publish` justamente pra não ser contornável pela flag.

Ordem interna do `release-publish`: `gh` autenticado (antes de qualquer push) → árvore limpa → nenhuma tag no origin em outro commit → notas não vazias + `main` + não atrás + nada estranho no HEAD → só a linha de versão mexida em cada pubspec → gate → `commit --only` com pathspec → **push da main** → cria e empurra as tags → dispara o `release.yml` **no ref da primeira tag**. Push recusado não deixa tag órfã (as tags vão num `push --atomic`); disparo recusado não desfaz tag — **re-rodar o mesmo `release-publish` retoma direto no disparo**, porque tag no origin apontando pro HEAD é estado de retomada, não versão queimada.

## 7. Conferir

```bash
git status --porcelain                                     # limpo
git ls-remote --tags origin | grep -E '<a>-v|<b>-v'        # tags no origin
gh run list --workflow=release.yml --limit 3               # "Release [PROD]" disparou
```

Relate por app: versão, tag e o run único. **Olhe o histórico**: se o run anterior falhou, avise — o novo pode cair pelo mesmo motivo.

## Guardrails

- **Nunca publique sem o OK do passo 5.** Produção não se desfaz.
- **Publicação parcial não queima versão**: tag local apontando pro HEAD sem par no origin é tentativa cujo push morreu — re-rode o mesmo `release-publish` e ele retoma. Só bumpe de novo se a tag **já estiver no origin**.
- **Tag no origin e deploy não disparado**: não bumpe. Rode o `gh workflow run release.yml --ref <tag> -f <app>=true` que a mensagem de erro imprime, ou marque os apps no `Run workflow` do **Release [PROD]**.
- **Nunca deixe bump não publicado na árvore**: ou publica, ou reverte (`git checkout -- apps/<app>`). Bump solto trava o `/release` seguinte e mente sobre a versão corrente.
- **Nunca rode `make test-all` solto "pra conferir"** — quem roda é a CI. Se o usuário quiser gate local mesmo assim, é o `release-publish` sem `SKIP_GATE=1`.
