---
name: "REPO: Commit"
description: Vê quais repos têm coisa para commitar e commita tudo (dart analyze antes, convenção emoji PT-BR)
category: Multi-repo
tags: [multi-repo, git, commit]
---

Varre os worktrees da branch `<nome>`, descobre quais repos têm diff e commita todos, em paralelo. Roda `dart analyze` antes em cada repo Dart e **não commita** o que falhar. Inclui sempre o `workspace` (change OpenSpec), que é commitado junto na branch.

**Input**: `$ARGUMENTS` = `<nome>` da branch (se vazio, inferir de `git branch --show-current`) + opcional mensagem.

> 🚦 **É o passo 4/4 do fechamento** (agente code-review → teste humano de integração → review humano → **repo flow**). Só roda **depois** de o usuário revisar o diff e aprovar explicitamente. Antes de commitar, apresente `python3 tool/repos.py status <nome>` + o diff de cada repo e **espere o OK**. Sem aprovação, não commite.

**Passos**

1. **Ver o que mudou** (rápido, não-mutante) — é o que você mostra pro usuário no gate:
   ```bash
   python3 tool/repos.py status <nome>
   ```

2. **Escolher a mensagem** seguindo **obrigatoriamente** `@.claude/rules/commit-convention.md` (PT-BR + emoji shortcode `:emoji: tipo: descrição`, emoji/tipo pelo conteúdo do diff). Se os repos sujos compartilham a mesma mudança lógica, uma mensagem serve para todos; se divergem, commite por repo com `--repos`.

3. **Commitar** (o script roda `dart analyze` antes em cada repo Dart, faz `add -A` + `commit`, em paralelo):
   ```bash
   # todos os repos sujos com a mesma mensagem:
   python3 tool/repos.py commit <nome> -m ":emoji: tipo: descrição"
   # ou por repo, quando o diff pede mensagem diferente:
   python3 tool/repos.py commit <nome> -m ":emoji: tipo: descrição" --repos <repo>
   ```
   O rodapé `Co-Authored-By` é exigência do harness — inclua-o na mensagem quando o commit for de código.

4. **Se um repo voltar ERRO** por `dart analyze`: corrija os arquivos apontados naquele worktree e re-rode o `commit` só dele (`--repos <repo>`). Os já commitados são pulados (sem diff).

**Guardrails**
- Sempre `@.claude/rules/commit-convention.md` (português + emoji `:shortcode: tipo:`).
- Não faz push (isso é do `/repo:pr`). Só commit local.
- Não commita repo com `dart analyze` falhando (use `--no-analyze` só se souber o que está fazendo).
