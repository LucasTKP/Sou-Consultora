---
name: "REPO: Switch"
description: Traz a branch <nome> pro seu ambiente principal (-m) pra testar/revisar, ou devolve pra worktree (-w)
category: Multi-repo
tags: [multi-repo, git, worktree, switch, review]
---

Traz a branch `<nome>` pro seu **ambiente principal** (o checkout onde o editor abre e o `pubspec` resolve — apps/features não resolvem isolados na worktree) só pra **testar e fazer code review**, e depois devolve pra worktree pra seguir o fluxo. **Não commita nada** — é um empréstimo temporário. Havendo repo de código com a branch, o `workspace` fica de fora (raiz do orquestrador + worktree esparsa da change OpenSpec). **Exceção:** quando a change só toca o `workspace` (skills, agentes, `openspec/config.yaml`) e nenhum repo de código tem a branch, o comando atende o próprio `workspace` — a raiz do orquestrador é que troca de branch. Sem isso o comando viraria no-op justamente na change que mais precisa de revisão no editor.

O **WIP não commitado viaja junto** (via `git stash`, compartilhado entre worktrees do mesmo repo), então você testa exatamente o estado atual da worktree, não uma versão velha. Não pergunta nem bloqueia.

**Input**: `$ARGUMENTS` = `<nome>` + **um** de `-m` / `-w`. Opcional: `--repos a,b` pra limitar o conjunto.

- `-m` (**meu ambiente principal**): guarda o WIP, remove a worktree de `<nome>`, faz `git switch <nome>` no dir principal e repõe o WIP lá. Aí é só rodar/testar/revisar.
- `-w` (**worktree**): guarda o WIP, volta o dir principal ao normal, **recria a worktree** e repõe o WIP nela — restaurando a invariante do fluxo (`/repo:commit`, `/repo:pr`, `/repo:merge` voltam a achar a worktree).

**Passos**

1. **Trazer pro meu ambiente** pra testar/revisar:
   ```bash
   python3 tool/repos.py switch <nome> -m            # ou --repos front-core,back-core
   ```
2. **Devolver pra worktree** quando terminar:
   ```bash
   python3 tool/repos.py switch <nome> -w
   ```

Caminho feliz é 100% script; só entre quando um repo der **ERRO**.

**Guardrails**
- Repos sem a branch `<nome>` são pulados. Idempotente: repetir `-m`/`-w` não faz nada além do já feito.
- WIP nunca é perdido nem commitado: ele é guardado no stash e reposto (no dir principal no `-m`, na worktree recriada no `-w`). Se o `pop` conflitar, o script reporta **ERRO** pra aquele repo.
- Não apaga branches nem PRs; `-w` só recria worktree e volta o principal ao normal.
