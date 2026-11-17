---
name: "REPO: PR"
description: Abre PR nos repos que têm commits na branch <nome> (push + gh pr create, em paralelo)
category: Multi-repo
tags: [multi-repo, github, pr]
---

Abre uma PR em cada repo que tem commits na branch `<nome>`, em paralelo (push + `gh pr create --fill`). Repos sem commit são pulados. O `workspace` entra sempre no conjunto (carrega a change OpenSpec) — se ele tiver commits, ganha PR próprio. Não mergeia (isso é o `/repo:merge`). Use quando quiser abrir a PR só para revisão; para abrir **e** mergear numa tacada, vá direto ao `/repo:merge`.

**Input**: `$ARGUMENTS` = `<nome>` da branch (se vazio, inferir de `git branch --show-current`) + opcional `--base <branch>` (default `main`) e `--repos a,b`.

**Passo único (caminho feliz)**:

```bash
python3 tool/repos.py pr <nome> [--base main] [--repos a,b] [--draft]
```

- Para cada repo com commits à frente da base: `git push -u origin <nome>` + `gh pr create --base <base> --head <nome> --fill` (título/corpo vêm dos commits). Se já existir PR aberto, reaproveita e imprime a URL.
- Idempotente: re-rodar não duplica PR.

**Cross-link (opcional)**: se a change tocou vários repos e você quer amarrar os PRs, faça uma 2ª passada com `gh pr edit <url> --body ...` referenciando os PRs irmãos e marcando **breaking** se aplicável — só quando agregar valor.

**Se um repo der ERRO**: analise (branch não pushada, sem permissão, base inexistente) e resolva; os outros PRs já foram abertos.

**Depois**: revisar e mergear com `/repo:merge <nome> --main` (ou `--stage`), ou mergear manualmente no GitHub. Se você não precisa revisar antes, pode ir direto ao `/repo:merge` — ele abre a PR que faltar.

**Guardrails**
- Confirmar com o usuário antes do primeiro push/PR.
- Não mergeia aqui — abertura só.
- Repo sem commit não vira PR (nada a propor).
