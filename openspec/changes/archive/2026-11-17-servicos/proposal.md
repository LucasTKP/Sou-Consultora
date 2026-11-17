# Proposal

## Why

A venda aceita produto **ou serviço** (unha, maquiagem, sobrancelha, tratamento), mas hoje Serviços é uma tela "em construção". Sem o catálogo de serviços, a fase de Vendas não consegue registrar atendimentos nem calcular o lucro deles (preço cobrado − custo de materiais). O dono do projeto decidiu fazer Serviços junto com Vendas e A receber.

## What Changes

- **Lista de serviços** (menu lateral → Serviços): busca por nome sem acento, filtro por categoria (com contagem), ordem por nome A-Z/Z-A, total cadastrado; card com foto (ou ícone), nome, categoria e preço cobrado; **Novo serviço**.
- **Cadastrar / Editar serviço** (uma tela): foto opcional (câmera/galeria, 1:1), nome e categoria obrigatórios, preço cobrado obrigatório (> 0), custo de materiais opcional, **retorno estimado** calculado na hora (preço − custo, em R$ e %), duração estimada opcional (15 min a 4 h) e observações. **Salvar serviço** grava e volta; a seta volta sem gravar.
- **Detalhes do serviço:** foto/ícone, categoria, nome, preço cobrado, custo de materiais, retorno estimado, duração, categoria e observações (vazios omitidos); **Editar serviço**. Sem exclusão.
- **Banco:** view `resumo_servicos` (com o nome da categoria) e trigger que exige categoria do tipo serviço; foto em `fotos/<id>/servicos/<momento>.jpg`.
- **Fora do escopo:** **Mais opções** (sem ações definidas no `fluxos.md`), cadastro de categorias, apagar serviço, `retorno_dias` (retorno da cliente — fica nulo até haver fluxo para ele).

## Capabilities

### New Capabilities
- `servicos`: catálogo de serviços da consultora (lista, cadastro com foto, detalhes e retorno estimado).

### Modified Capabilities
- (nenhuma)

## Impact

- **Banco:** migração `..._servicos.sql` (view + trigger) e `supabase/tests/10_servicos.sql` (integridade e isolamento A × B × anon).
- **App:** `core` (dto, model, service, repository de serviço; `MudancaFoto` sai de `repositorio_produtos` para `core/model/mudanca_foto.dart` e é reaproveitada); `ui/modules/servicos/` (lista, formulario, detalhes); rotas `/servicos/novo`, `/servicos/:id`, `/servicos/:id/editar`.
- **Testes:** unitários, de widget e o grupo E2E-08.
