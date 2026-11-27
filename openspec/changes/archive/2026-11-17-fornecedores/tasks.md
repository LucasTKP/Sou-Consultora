# Tasks

## 1. Banco

- [x] 1.1 Conferir `testes.popular` em `supabase/tests/auxiliares/` (fornecedor só com nome, compatível com o CHECK novo) e ajustar se preciso; verificar com `supabase db reset && supabase test db` passando antes da migração nova
- [x] 1.2 Criar a migração `..._fornecedores.sql`: normalizar telefones existentes, CHECK `telefone ~ '^[0-9]{10,11}$'`, índice único `(consultora_id, lower(btrim(nome)))`, índice parcial de boletos em aberto por vencimento (se não existir) e a view `resumo_fornecedores` (`security_invoker`, `select` só para `authenticated`); verificar com `supabase db reset` sem erros
- [x] 1.3 Criar `supabase/tests/07_fornecedores.sql`. Integridade: telefone com máscara recusado, " NATURA " repetido recusado, mesmo nome em consultoras diferentes aceito. View: em aberto, atrasados, vence hoje e pagos com boletos de teste; fornecedor sem boletos com zeros. Isolamento: A não lê o resumo nem os fornecedores de B, update de A no fornecedor de B não altera nada, insert com `consultora_id` de B recusado, os números de A não contam boletos de B, `anon` não lê a tabela nem a view. Verificar com `supabase test db` passando

## 2. Erros, model e DTO

- [x] 2.1 Adicionar `FalhaValidacao` em `core/erros/falha_app.dart` e mapear `PostgrestException` `23505` em `core/erros/mapeador_falhas.dart` (mensagem informada pelo service); verificar com teste unitário do mapeador (23505 → `FalhaValidacao` com a mensagem; outros códigos continuam `FalhaInesperada`)
- [x] 2.2 Mover `OrdemNome` para `core/model/ordem_nome.dart` e atualizar os imports de Clientes; verificar com `flutter test test/core test/ui/modules` (testes de Clientes passando)
- [x] 2.3 Criar `core/model/fornecedor.dart` (validações de nome e telefone, `paraGravar()` com vazios → `null`, `ativo` só na edição); verificar com teste unitário (nome vazio, telefone incompleto, telefone vazio aceito, campos opcionais vazios viram `null`)
- [x] 2.4 Criar `core/model/resumo_fornecedor.dart` e `core/model/filtro_fornecedores.dart` (status com prioridade vence hoje > em espera > ativo, iniciais "NAT"/"OB"/"AE", texto de boletos em aberto no singular e no plural, busca sem acento, filtros com contagem, ordem A-Z/Z-A); verificar com teste unitário cobrindo cada linha da prioridade, "boticario" → "O Boticário" e o filtro "Vence hoje" incluindo quem está em espera
- [x] 2.5 Criar `core/dto/resumo_fornecedor_dto.dart` com `fromJson` e `paraModel` (numeric como `int`, `double` ou `String`); verificar com teste unitário de conversão

## 3. Service, repositório e DI

- [x] 3.1 Criar `core/service/servico_fornecedores.dart` (`listarResumos`, `buscarResumo`, `criar`, `atualizar` via `ApiSupabase`); verificar com teste unitário usando api falsa (sucesso, falha de rede, duplicado → `FalhaValidacao`, dados enviados sem `consultora_id`/`id`/`created_at`)
- [x] 3.2 Criar `core/repository/repositorio_fornecedores.dart` (cache, `Stream`, recarregar após salvar, limpar ao encerrar a sessão, `abrirWhatsapp`) e registrar serviço e repositório no `injetor`; verificar com teste unitário (salvar emite a lista nova; falha ao salvar não altera o cache; sessão encerrada limpa o cache)

## 4. Navegação e widget compartilhado

- [x] 4.1 Criar `ui/widgets/formularios/interruptor_app.dart` (`Switch` com rótulo e descrição); verificar com widget test (alternar chama `onChanged`)
- [x] 4.2 Trocar a rota "em construção" de `/fornecedores` pela lista e criar `/fornecedores/novo`, `/fornecedores/:id` e `/fornecedores/:id/editar` no navegador raiz (constantes em `RotasApp`); verificar com os testes de navegação atualizados (lista com barra, detalhe sem barra, voltar)

## 5. Telas

- [x] 5.1 Criar `ui/modules/fornecedores/lista/` (state, cubit, screen, `widgets/cartao_fornecedor.dart`): busca, filtro com contagens, ordem, contador "N fornecedores", selos, vazio, sem resultado, erro e o botão "Fornecedor" acima da barra; verificar com testes do cubit (filtrar, buscar, ordenar, stream atualiza) e widget test (selos, "Nenhum boleto em aberto", vazio, erro com tentar novamente)
- [x] 5.2 Criar `ui/modules/fornecedores/formulario/` (novo e editar, interruptor Em espera só na edição, aviso de erro mantendo os dados, Cancelar sem gravar); verificar com testes do cubit (nome vazio não grava, telefone incompleto, duplicado mostra o aviso e mantém os campos, editar envia `ativo`) e widget test (título "Novo" × "Editar", interruptor ausente no novo)
- [x] 5.3 Criar `ui/modules/fornecedores/detalhes/` (identidade com "Parceiro desde mmm/aaaa", cartão Boletos com os 3 blocos e Ver em A pagar, contato com campos vazios omitidos e WhatsApp com aviso de falha, Editar e recarregar na volta, sem botão de excluir); verificar com widget test usando serviço falso de WhatsApp (sem telefone esconde o botão; zeros sem boletos)

## 6. Integração e documentação

- [x] 6.1 Acrescentar o grupo `E2E-05 Fornecedores` em `integration_test/app_e2e_test.dart` (cadastrar com nome único prefixado `E2E`, ver na lista, buscar, abrir detalhes, editar colocando em espera e voltar a ativo) e atualizar a tabela de cobertura e o checklist manual do README (WhatsApp do fornecedor); verificar com `flutter analyze` (o E2E só roda antes de lançar)
- [x] 6.2 Atualizar `../fluxos.md` (status com prioridade, "em aberto" inclui atrasados, sem foto/e-mail, sem exclusão) e `../banco-de-dados.md` (formato do telefone, nome único, `resumo_fornecedores`); verificar a consistência com a spec
- [x] 6.3 Rodar `flutter analyze` e `flutter test`; verificar zero problemas novos e todos os testes passando
- [x] 6.4 Aplicar a migração no remoto **só após a confirmação do dono do projeto** (conferir antes nomes repetidos e telefones fora do formato) — aplicada em 2026-11-17 com a confirmação do dono (`db push` sem erros; o índice único foi criado, então não havia nomes repetidos)
- [ ] 6.5 Percurso manual no aparelho: cadastrar, buscar, filtrar, abrir detalhes, WhatsApp, editar e colocar em espera; registrar o resultado (pode ser adiado para a rodada de conferência antes de lançar, como a 6.4 de Clientes) — **adiada** para a rodada de conferência antes de lançar (item no checklist manual de `integration_test/README.md`)

## Resultado

- `supabase test db`: **143 testes** (18 novos em `07_fornecedores.sql`: formato do telefone, nome repetido com maiúsculas/espaços, mesmo nome em consultoras diferentes, números da view com boletos de teste, isolamento A × B × anon).
- `flutter test`: **208 testes** (novos: mapeador de falhas 3, models/DTO 12, service 5, repositório 4, interruptor 1, telas e cubits 15; testes de navegação passaram a registrar o repositório de fornecedores e esperam a lista real).
- `flutter analyze`: só os 2 avisos antigos (`tipografia_app.dart` e `perfil_test.dart`).
- Decisões de implementação:
  - `FalhaValidacao` nova; `PostgrestException 23505` só vira essa falha quando o service informa a mensagem de duplicado;
  - `OrdemNome` saiu de `filtro_clientes.dart` para `core/model/ordem_nome.dart`;
  - `FormatadorData.mesAnoCurto` ("mar/2023") para "Parceiro desde";
  - interruptor feito com `Switch` do Material (não `ShadSwitch`), como os demais campos.
- E2E-05 executado depois, no emulador Android (`flutter drive --keep-app-running`, `E2E_GRUPO=E2E-05`): **2 cenários passando**. O fornecedor fixo agora é compartilhado com o E2E-06 (`fornecedorE2e`, com telefone e ramo).
