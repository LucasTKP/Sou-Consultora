# Design

## Context

- `servicos` já existe (nome, `categoria_id` com FK composta, `preco_cobrado >= 0`, `custo_materiais >= 0`, `duracao_minutos > 0`, `retorno_dias > 0`, observações, `foto_url`), com RLS e 4 policies. Nada impede categoria do tipo produto.
- Produtos já resolveu: categorias (`RepositorioCategorias`), foto (envia → grava → apaga antiga), URLs assinadas em lote, cache + `Stream`, telas lista/form/detalhes. Serviços repete esse desenho.
- `/servicos` é um módulo "em construção" aberto pelo menu lateral (fora da barra).

## Goals / Non-Goals

**Goals:** catálogo pronto para a venda (preço e custo de materiais), mesmo padrão de Produtos, reaproveitando código em vez de copiar.

**Non-Goals:** Mais opções, apagar serviço, cadastro de categorias, `retorno_dias`.

## Decisions

### 1. Banco (`..._servicos.sql`)
- Trigger `preparar_servico` (`before insert or update of categoria_id, consultora_id`): recusa categoria que não seja do tipo `servico` (`23514`), como `preparar_produto`.
- View `resumo_servicos` (`security_invoker`): colunas de `servicos` + `categoria_nome`. `select` só para `authenticated`.

### 2. Reaproveitamento
- `MudancaFoto` (`ManterFoto`, `TrocarFoto`, `RemoverFoto`) sai de `repositorio_produtos.dart` para `core/model/mudanca_foto.dart`.
- `RepositorioCategorias` ganha `deServico()` (mesmo cache por tipo); `ServicoCategorias.listarDeServico()`.
- `Margem` (de estoque) calcula o retorno estimado: `Margem.calcular(precoVenda: preco, custo: custo ?? 0)`.

### 3. Camadas
| Camada | Arquivo |
|---|---|
| dto | `core/dto/resumo_servico_dto.dart` |
| model | `core/model/servico.dart` (dados editáveis, validações, `paraGravar`), `core/model/resumo_servico.dart` (+ `retorno`, `textoDuracao`), `core/model/duracao_servico.dart` (opções 15, 30, 45, 60, 90, 120, 150, 180, 240 min e textos "1h 30min"), `core/model/filtro_servicos.dart` |
| service | `core/service/servico_servicos.dart` (listar, buscar, criar, atualizar, foto em `<id>/servicos/<momento>.jpg`, URLs) |
| repository | `core/repository/repositorio_servicos.dart` (cache + `Stream`, `salvar` com `MudancaFoto`, limpa na sessão encerrada) |

### 4. Telas (`ui/modules/servicos/`)
- `lista/` na casca (menu), com `CabecalhoApp` de menu, busca, filtro de categoria com contagens, ordem por nome, FAB **Novo serviço** acima da barra.
- `formulario/` (raiz): título "Cadastrar Serviço"/"Editar Serviço"; cartão "Como funciona"; foto (reusa `FolhaFotoApp` e um campo de foto compartilhado `ui/widgets/formularios/campo_foto_app.dart`, extraído de `campo_foto_produto.dart`); cartão de retorno estimado; **Salvar Serviço** no rodapé.
- `detalhes/` (raiz): cartão de identidade, dois cartões (custo e retorno), linhas de duração, categoria e observações; **Editar Serviço**.
- Ícone de reserva por categoria (unhas → mão, maquiagem → pincel, sobrancelha → olho, facial → folha, depilação → spa).

## Risks / Trade-offs
- [Duas telas parecidas (Produtos × Serviços)] → regras e componentes comuns ficam no core e em `ui/widgets`; as telas continuam por feature, como a arquitetura pede.

## Migration Plan
1. `supabase db reset && supabase test db` local.
2. `supabase db push` (autorizado pelo dono para esta fase).
3. Rollback: derrubar a view e o trigger.
