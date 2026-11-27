---
name: "REPO: Status"
description: Estado da branch <nome> em todos os repos — branch, diff, commits à frente, worktree
category: Multi-repo
tags: [multi-repo, git, github, status]
---

Visão rápida (paralela, só-leitura) de uma branch `<nome>` através de todos os repos.

**Input**: `$ARGUMENTS` = `<nome>` da branch (se vazio, inferir de `git branch --show-current`).

**Passo único**:

```bash
python3 tool/repos.py status <nome>
```

Mostra, por repo: se tem a branch, se o worktree está limpo/sujo (nº de arquivos), quantos commits à frente da base, e o caminho do worktree. Repos sem a branch aparecem como `(sem branch)`.

**PRs (opcional)**: para ver o estado das PRs abertas de `<nome>`, use `gh pr list --head <nome>` por repo (ou olhe a saída do `/repo:pr`).

**Guardrails**
- Só leitura. Não altera branches, refs, PRs nem worktrees.
