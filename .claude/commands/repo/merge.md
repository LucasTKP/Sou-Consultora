---
name: "REPO: Merge"
description: Abre a PR (se faltar) e mergeia em ordem topológica — --main ou --stage
category: Multi-repo
tags: [multi-repo, github, merge, release]
---

Fecha o ciclo: garante a PR aberta em cada repo que mudou **e mergeia**, em ordem topológica (produtor antes do consumidor). Escolha a base pelo flag: `--main` ou `--stage`. É idempotente — se você já rodou `/repo:pr`, a etapa de PR só reaproveita o que existe; se não rodou, o próprio `merge` abre a PR que falta. O `workspace` (change OpenSpec) entra sempre no conjunto e mergeia junto — como não tem `depends_on`, cai cedo na ordem topológica.

**Input**: `$ARGUMENTS` = `<nome>` da branch (se vazio, inferir de `git branch --show-current`) + **`--main`** ou **`--stage`** (obrigatório) + opcional `--repos a,b`.

**Passo único (caminho feliz)** — o `merge` já abre a PR que faltar:

```bash
python3 tool/repos.py merge <nome> --main  [--repos a,b]
python3 tool/repos.py merge <nome> --stage [--repos a,b]
```

O `merge` faz as duas etapas por repo: se não há PR aberta de `<nome>`, ele faz `push` + `gh pr create --fill` e então mergeia; se já há (porque você rodou `/repo:pr` antes para revisar), reaproveita. Repos sem commit à frente da base são pulados.

O merge em si é em ordem topológica (derivada de `depends_on` no `repos.yaml`), `gh pr merge --squash --delete-branch`, sequencial — nunca mergeia consumidor antes do produtor.

> `--main`/`--stage` são atalhos para `--base main`/`--base stage`; `--base X` aceita base arbitrária. Os três são mutuamente exclusivos e o default é `main`.

**`--stage`**: exige que a branch `stage` exista no remoto de cada repo. Se o `gh` reclamar que a base não existe, crie a `stage` (a partir da `main`) e rode de novo.

**Se algum merge der ERRO** (conflito, checks vermelhos, review pendente): o script não reporta sucesso naquele repo — resolva a PR no GitHub e re-rode o `merge` (os já mergeados são pulados por não terem mais PR aberto).

**Depois**: `/repo:clean <nome>` para remover os worktrees.

**Guardrails**
- Ação externa e irreversível: confirme com o usuário antes de mergear.
- Nunca mergeia consumidor antes do produtor (a ordem topológica garante).
- Só uma base por vez — não misture `--main` e `--stage`.
