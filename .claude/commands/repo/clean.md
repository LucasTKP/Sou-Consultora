---
name: "REPO: Clean"
description: Remove os worktrees da branch <nome> preservando branches e PRs — último passo do fluxo
category: Multi-repo
tags: [multi-repo, git, worktree, clean]
---

Último passo do fluxo (depois do `/repo:merge`). Remove os worktrees de `<nome>` em todos os repos (paralelo), sem apagar branches locais/remotas nem PRs.

**Input**: `$ARGUMENTS` = `<nome>` da branch.

**Passos**

1. **Sanidade** (opcional, recomendado antes de limpar): `python3 tool/repos.py status <nome>` — avise e confirme com o usuário se algum worktree tiver diff não commitado ou commits não pushados.

2. **Remover os worktrees**:
   ```bash
   python3 tool/repos.py rm <nome>            # use --force só se confirmar diff descartável
   ```
   O script remove todos os worktrees sob `.worktrees/<nome>/` (e variantes `.worktrees/<nome>.<sufixo>/` de agentes), roda `worktree prune` e apaga a pasta se ficar vazia.

3. **Branches**: **preservadas** por padrão (locais e remotas) — o `rm` não toca em branch. Delete manualmente se quiser (`git -C <path> branch -D <nome>`); nunca delete a remota automaticamente.

**Guardrails**
- Nunca remover worktree com trabalho não salvo sem confirmação (`--force`).
- Nunca deletar branch remota nem fechar PR automaticamente.
- `.worktrees/` continua fora do versionamento.
