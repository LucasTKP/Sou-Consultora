# Convenção de Commits (Sou Consultora)

## 🚨 Regras obrigatórias
- SEMPRE em **português**. NUNCA em inglês.
- SEMPRE com emoji identificando o tipo.
- Formato do assunto: `:emoji: tipo({feature-or-app-or-service}): Descrição em português`
- Rodapé obrigatório **em commit autorado por agente** (exigência do harness), após uma linha em branco:
  ```
  Co-Authored-By: Claude <modelo em uso> <noreply@anthropic.com>
  ```
  O `<modelo em uso>` é o que o harness informa **naquela sessão** (ex.: `Opus 5 (1M context)`) — não chumbe uma versão aqui, senão a regra envelhece e passa a conflitar com o rodapé que o harness exige.
  Commit gerado por ferramenta do repo e rodado por humano (ex.: o bump de versão do `make release-publish`) **não** leva o rodapé — atribuir um modelo ali atribuiria errado toda release futura.
- Emoji no formato **shortcode** (`:sparkles:`), não o unicode — o GitHub renderiza.

## 📋 Tipos com emoji

### ✨ Novos recursos
- `:sparkles: feat({feature-or-app-or-service}):` — Novo recurso/funcionalidade
- `:lipstick: feat({feature-or-app-or-service}):` — Estilização de interface
- `:wheelchair: feat({feature-or-app-or-service}):` — Acessibilidade
- `:iphone: feat({feature-or-app-or-service}):` — Responsividade
- `:dizzy: feat({feature-or-app-or-service}):` — Animações e transições

### 🐛 Correções
- `:bug: fix({feature-or-app-or-service}):` — Correção de bugs
- `:boom: fix({feature-or-app-or-service}):` — Revertendo mudanças
- `:goal_net: fix({feature-or-app-or-service}):` — Tratamento de erros

### ♻️ Melhorias
- `:recycle: refactor({feature-or-app-or-service}):` — Refatoração de código
- `:zap: perf({feature-or-app-or-service}):` — Melhorias de performance
- `:broom: cleanup({feature-or-app-or-service}):` — Limpeza de código
- `:construction: feat({feature-or-app-or-service}):` — Em progresso

### 📚 Documentação
- `:books: docs({feature-or-app-or-service}):` — Documentação
- `:bulb: docs({feature-or-app-or-service}):` — Comentários
- `:pencil: docs({feature-or-app-or-service}):` — Texto

### 🧪 Testes
- `:test_tube: test({feature-or-app-or-service}):` — Testes
- `:white_check_mark: test({feature-or-app-or-service}):` — Adicionando teste
- `:heavy_check_mark: test({feature-or-app-or-service}):` — Teste de aprovação

### 🔧 Configuração
- `:wrench: chore({feature-or-app-or-service}):` — Configuração
- `:truck: chore({feature-or-app-or-service}):` — Mover/renomear
- `:bricks: ci({feature-or-app-or-service}):` — Infraestrutura
- `:package: build({feature-or-app-or-service}):` — Dependências

### 📦 Build e dependências
- `:heavy_plus_sign: build({feature-or-app-or-service}):` — Adicionando dependência
- `:heavy_minus_sign: build({feature-or-app-or-service}):` — Removendo dependência
- `:arrow_up: chore({feature-or-app-or-service}):` — Atualizando versão
- `:arrow_down: chore({feature-or-app-or-service}):` — Retrocedendo versão

### 🗑️ Remoções
- `:wastebasket: remove({feature-or-app-or-service}):` — Removendo arquivos
- `:card_file_box: raw({feature-or-app-or-service}):` — Dados

### 🎯 Outros
- `:tada: init({feature-or-app-or-service}):` — Commit inicial
- `:rocket: feat({feature-or-app-or-service}):` — Deploy
- `:lock: feat({feature-or-app-or-service}):` — Segurança
- `:mag: feat({feature-or-app-or-service}):` — SEO
- `:bookmark: feat({feature-or-app-or-service}):` — Tag de versão
- `:label: feat({feature-or-app-or-service}):` — Tipagem
- `:soon: feat({feature-or-app-or-service}):` — Lista de ideias

## 🔀 Commits da orquestração multi-repo (`repo:*`)
- Commit de código (`/repo:commit`): escolher o emoji/tipo pelo conteúdo do diff daquele repo.
- Re-pin de dependência (`/repo:merge`, troca de `ref`/`pubspec.lock`): usar `:package: build({repo}):` — o escopo já nomeia o repo, então a descrição não o repete.

**Exemplos** (escopo real, nunca o placeholder literal)
```
:sparkles: feat(billing): Adiciona campo opcional loyaltyId no CustomerDto
:bug: fix(pdv): Corrige cálculo de acréscimo na sessão do pdv
:package: build(shared_contracts): Re-pin para main
```
