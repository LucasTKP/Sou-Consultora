---
name: "REPO: Bootstrap"
description: Gera/valida o manifesto repos.yaml dos repos do workspace e prepara o .gitignore para worktrees
category: Multi-repo
tags: [multi-repo, git, manifest, setup]
---

Prepara o workspace para a orquestração multi-repo. Idempotente: pode rodar quantas vezes quiser.

Referência de arquitetura: `openspec/changes/multi-repo-branch-orchestration/` (design D1, D6–D10).

**Passos**

1. **Gerar/atualizar `repos.yaml` na raiz do workspace** com exatamente estas 12 entradas (fonte única de verdade da topologia). Se já existir, faça merge preservando edições manuais, mas garanta que os campos abaixo batem:

   ```yaml
   # repos.yaml — manifesto dos repos git do workspace (meta-repo recursivo, 2 níveis)
   repos:
     - name: workspace
       path: .
       remote: https://github.com/artizan-paipfood/workspace.git
       owner: artizan-paipfood
       base_branch: main
       parent: null
       deployable: false
       depends_on: []
     - name: shared_contracts
       path: shared_contracts
       remote: https://github.com/artizan-paipfood/shared_contracts.git
       owner: artizan-paipfood
       base_branch: main
       parent: null
       deployable: false
       depends_on: []
     - name: analysis_options_shared
       path: analysis_options_shared
       remote: https://github.com/artizan-paipfood/analysis_options_shared.git
       owner: artizan-paipfood
       base_branch: main
       parent: null
       deployable: false
       dev_only: true          # lint/dev-time — não impõe gate de deploy nem ordem de runtime
       depends_on: []
     - name: ds_ui
       path: ds_ui
       remote: https://github.com/eduardohr-muniz/artizan_ui
       owner: eduardohr-muniz   # exceção: owner distinto
       base_branch: migration-ds # exceção: base != main
       parent: null
       deployable: false
       depends_on: []
     - name: back-core
       path: back-core
       remote: https://github.com/artizan-paipfood/back-core.git
       owner: artizan-paipfood
       base_branch: main
       parent: null
       deployable: true          # tem CI de deploy (manual)
       depends_on: [shared_contracts, analysis_options_shared]
     - name: front-core
       path: front-core
       remote: https://github.com/artizan-paipfood/front-core.git
       owner: artizan-paipfood
       base_branch: main
       parent: null
       deployable: true          # tem CI de deploy que builda os apps (manual)
       depends_on: [shared_contracts, ds_ui, analysis_options_shared]
     - name: admin
       path: front-core/apps/admin
       remote: https://github.com/artizan-paipfood/admin.git
       owner: artizan-paipfood
       base_branch: main
       parent: front-core
       deployable: false         # deploya via CI do front-core
       depends_on: [front-core]
     - name: app
       path: front-core/apps/app
       remote: https://github.com/artizan-paipfood/app.git
       owner: artizan-paipfood
       base_branch: main
       parent: front-core
       deployable: false
       depends_on: [front-core]
     - name: console
       path: front-core/apps/console
       remote: https://github.com/artizan-paipfood/console.git
       owner: artizan-paipfood
       base_branch: main
       parent: front-core
       deployable: false
       depends_on: [front-core]
     - name: landing_page
       path: front-core/apps/landing_page
       remote: https://github.com/artizan-paipfood/landing-page.git  # exceção: remote com hífen
       owner: artizan-paipfood
       base_branch: main
       parent: front-core
       deployable: false
       depends_on: [front-core]
     - name: pdv
       path: front-core/apps/pdv
       remote: https://github.com/artizan-paipfood/pdv.git
       owner: artizan-paipfood
       base_branch: main
       parent: front-core
       deployable: false
       depends_on: [front-core]
     - name: portal
       path: front-core/apps/portal
       remote: https://github.com/artizan-paipfood/portal.git
       owner: artizan-paipfood
       base_branch: main
       parent: front-core
       deployable: false
       depends_on: [front-core]
   ```

2. **Garantir `.worktrees/` no `.gitignore` da raiz** (uma linha `.worktrees/`). Não duplicar se já existir.

3. **Validar contra o disco** — para cada entrada com `path` diferente de `.`:
   - Confirmar que `<path>/.git` existe (é repo git). Se não, reportar como divergência.
   - Rodar `git -C <path> remote get-url origin` e comparar com `remote` do manifesto (ignorando `.git` final e `https`/`ssh`). Divergência → reportar repo, esperado e encontrado.
   - Rodar `git -C <path> branch --show-current` e avisar se difere de `base_branch` (informativo, não é erro).

4. **Reportar** uma tabela: repo · path · remote OK/divergente · branch atual vs base. Ao final, dizer se o workspace está pronto (`repos.yaml` válido + `.gitignore` ok) ou listar as divergências a resolver.

**Guardrails**
- Só escreve `repos.yaml` e `.gitignore` na raiz. Não toca nos sub-repos.
- Não commita nada — apenas cria/edita os arquivos e reporta.
