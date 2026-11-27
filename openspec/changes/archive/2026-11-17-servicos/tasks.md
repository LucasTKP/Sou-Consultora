# Tasks

## 1. Banco

- [x] 1.1 Criar a migração `..._servicos.sql` (trigger de categoria do tipo serviço e view `resumo_servicos`) e `supabase/tests/10_servicos.sql` (categoria de produto recusada, preço negativo e duração 0 recusados, view com o nome da categoria, isolamento A × B × anon, foto na pasta de B recusada); verificar com `supabase db reset && supabase test db`

## 2. Core

- [x] 2.1 Mover `MudancaFoto` para `core/model/mudanca_foto.dart`; criar `servico.dart`, `resumo_servico.dart`, `duracao_servico.dart`, `filtro_servicos.dart` e `resumo_servico_dto.dart`; verificar com teste unitário (validações, retorno 80%, textos de duração, filtro/ordem, DTO)
- [x] 2.2 Criar `servico_servicos.dart`, `repositorio_servicos.dart`, `deServico()` nas categorias e registrar no `injetor`; verificar com teste unitário (dados sem `consultora_id`, foto na pasta `servicos`, salvar troca a foto e apaga a antiga)

## 3. Telas e navegação

- [x] 3.1 Extrair `ui/widgets/formularios/campo_foto_app.dart` do campo de foto de Produtos; criar `ui/modules/servicos/` (lista, formulario, detalhes) e as rotas; verificar com testes de widget (lista, vazio, erro, filtro; formulário com retorno estimado e obrigatórios; detalhes com vazios omitidos) e o teste de navegação pelo menu

## 4. Integração

- [x] 4.1 Grupo `E2E-08 Serviços` (cadastrar "E2E Serviço" uma vez, buscar, abrir detalhes, editar o preço e restaurar) + README; atualizar `../fluxos.md` e `../banco-de-dados.md`
- [x] 4.2 `flutter analyze`, `flutter test`, `supabase test db`; aplicar no remoto e rodar o E2E-08

## Resultado

- `supabase test db`: 203 testes (12 novos em `10_servicos.sql`). `flutter test`: 285. `flutter analyze`: só os 2 avisos antigos.
- Migração aplicada no remoto (autorizado pelo dono para esta fase) e E2E-08 passando no emulador Android.
- Reaproveitamento: `MudancaFoto` em `core/model`, `gravarComFoto` em `core/repository/gravacao_com_foto.dart` (Produtos passou a usar), `CampoFotoApp` em `ui/widgets/formularios`, categorias por tipo no `RepositorioCategorias`, `Margem` para o retorno estimado.
- Percurso manual adiado para a rodada antes de lançar (checklist do README).
