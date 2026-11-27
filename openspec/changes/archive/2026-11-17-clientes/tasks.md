# Tasks

## 1. Banco

- [x] 1.1 Ajustar `testes.popular` em `supabase/tests/auxiliares/` para gravar o WhatsApp da cliente só com dígitos; verificar com `supabase db reset && supabase test db` passando antes da migração nova
- [x] 1.2 Criar a migração `..._clientes.sql` com os CHECKs de WhatsApp e nascimento, o índice `clientes (consultora_id, nome)` (e `vendas (cliente_id)` se não existir), a view `resumo_clientes` (`security_invoker`) e a RPC `salvar_cliente` (`security invoker`, `execute` só para `authenticated`); verificar com `supabase db reset` sem erros
- [x] 1.3 Criar `supabase/tests/06_clientes.sql`. Integridade: WhatsApp com máscara e nascimento futuro são recusados. RPC: cria com e sem endereço, edita, remove o endereço e não deixa órfão. View: saldo, atrasado, vence hoje e pago parcial com venda de teste. Isolamento: A não lê o resumo de B, a RPC com id de B falha sem alterar nada, A não vincula endereço de B, `anon` não lê a view nem executa a RPC. Verificar com `supabase test db` passando

## 2. Model e DTO

- [x] 2.1 Criar `core/model/endereco.dart` e `core/model/cliente.dart` (validações, `iniciais`, linhas de exibição); verificar com teste unitário (endereço vazio, só bairro → rua e número obrigatórios, nascimento futuro, WhatsApp inválido)
- [x] 2.2 Criar `core/model/resumo_cliente.dart` e `core/model/filtro_clientes.dart` (situação com prioridade, aniversariante no mês, busca sem acento, filtros com contagem, ordem A-Z/Z-A); verificar com teste unitário cobrindo cada linha da prioridade e "patricia" → "Patrícia"
- [x] 2.3 Criar `core/dto/resumo_cliente_dto.dart`, `cliente_dto.dart` e `endereco_dto.dart` com `fromJson` e `paraModel` (numeric chegando como `int`, `double` ou `String`); verificar com teste unitário de conversão

## 3. Services, repositório e DI

- [x] 3.1 Criar `core/service/servico_clientes.dart` (listar resumos, buscar resumo, buscar cliente com endereço, salvar via RPC) com mapeamento para `FalhaApp`; verificar com teste unitário usando api falsa (sucesso, falha de rede, parâmetros da RPC sem `consultora_id`)
- [x] 3.2 Criar `core/service/servico_cep.dart` (ViaCEP com `http.Client` injetado e timeout); verificar com teste unitário usando `MockClient` (encontrado, `{"erro": true}`, timeout, CEP com menos de 8 dígitos sem chamar a rede)
- [x] 3.3 Adicionar `url_launcher`, criar `core/service/servico_whatsapp.dart` e configurar `Info.plist` e `AndroidManifest` (`queries`); verificar com `flutter build ios --simulator` e teste unitário do link gerado (`https://wa.me/5511987654321`)
- [x] 3.4 Criar `core/repository/repositorio_clientes.dart` (cache, `Stream`, recarregar após salvar) e registrar tudo no `injetor`; verificar com teste unitário (salvar emite a lista nova; falha ao salvar não altera o cache)

## 4. Navegação

- [x] 4.1 Trocar a rota "em construção" de `/clientes` pela lista e criar `/clientes/novo`, `/clientes/:id`, `/clientes/:id/dados` e `/clientes/:id/editar` no navegador raiz (constantes em `RotasApp`); verificar com os testes de navegação atualizados (lista com barra, detalhe sem barra, voltar)

## 5. Telas

- [x] 5.1 Criar `ui/modules/clientes/lista/` (state, cubit, screen, `widgets/cartao_cliente.dart`): filtro com contagens, busca, ordem, contador, selos, vazio, sem resultado, erro e o botão Novo cliente; verificar com testes do cubit (filtrar, buscar, ordenar, stream atualiza) e widget test (selos, vazio, erro com tentar novamente)
- [x] 5.2 Criar `ui/modules/clientes/formulario/` (2 passos, novo e editar, CEP automático, voltar do passo 2 para o 1, aviso de erro mantendo os dados); verificar com testes do cubit (passo 1 inválido não avança, endereço incompleto, CEP preenche, salvar sem endereço, edição remove endereço, falha mantém os dados) e widget test (título "Novo" × "Editar", indicador de passo)
- [x] 5.3 Criar `ui/modules/clientes/detalhes/` (iniciais, nome, selo do saldo, Dados cadastrais, Compras e Nova venda indo para "em construção"); verificar com widget test (com saldo, sem compras "Nenhum pedido ainda")
- [x] 5.4 Criar `ui/modules/clientes/dados/` (seções com `TituloSecaoApp`, campos vazios omitidos, "Endereço não cadastrado", Abrir WhatsApp com aviso de falha, Editar e recarregar na volta); verificar com widget test usando serviço falso de WhatsApp

## 6. Integração e documentação

- [x] 6.1 Acrescentar o grupo `E2E-04 Clientes` em `integration_test/app_e2e_test.dart` (cadastrar com nome único, ver na lista, buscar, abrir os dados, editar e voltar; a limpeza via `addTearDown` não apaga, então marcar o nome com prefixo `E2E`) e atualizar a tabela de cobertura e o checklist manual do README (Abrir WhatsApp real, CEP real); verificar com `flutter analyze` (o E2E só roda antes de lançar)
- [x] 6.2 Atualizar `../fluxos.md` (selos, filtros, CEP automático, Compras em construção) e `../banco-de-dados.md` (formato do WhatsApp da cliente, `resumo_clientes`, `salvar_cliente`); verificar a consistência com a spec
- [x] 6.3 Rodar `flutter analyze` e `flutter test`; verificar zero problemas novos e todos os testes passando
- [x] 6.4 Rodar no simulador: cadastrar com e sem endereço (CEP real), buscar, filtrar, abrir os dados, Abrir WhatsApp, editar; registrar o resultado (percurso manual feito pelo dono do projeto)
  - **Parcial (17/11/2026, emulador Android):** ok — cadastrar sem endereço, lista atualiza, detalhes ("Nenhum pedido ainda"), dados ("Endereço não cadastrado", aniversário "15 de março"), Abrir WhatsApp (sem o app, abre `api.whatsapp.com` no navegador).
  - **Bug achado e corrigido:** o botão **Novo cliente** ficava atrás da barra inferior (a casca usa `extendBody`); agora soma `MediaQuery.paddingOf(context).bottom`, e a lista ganhou o mesmo espaço no fim.
  - **Adiado** (o emulador fechou; decisão do dono do projeto): cadastrar com CEP real, buscar, filtrar, editar e conferir o botão corrigido. Entrou no checklist manual de `integration_test/README.md`, para rodar junto com a conferência antes de lançar.

## Resultado

- 1.1: `testes.popular` já gravava o WhatsApp só com dígitos; nada a mudar. O índice `vendas (cliente_id)` também já existia.
- `supabase test db`: **125 testes** (27 novos em `06_clientes.sql`: RPC, formatos, view com pagamento parcial, isolamento A × B × anon).
- `flutter test`: **166 testes** (novos: models/DTOs 14, services 9, repositório 3, telas e cubits 20, navegação 1).
- `flutter analyze`: só o aviso antigo de `ui/temas/tipografia_app.dart`. `flutter build ios --simulator` ok.
- Ajustes em componentes compartilhados descobertos pelos testes:
  - `CampoSelecaoApp` atualiza o texto quando o rótulo muda com o mesmo valor (contagens do filtro);
  - `CampoTextoApp` aceita `focusNode`;
  - `BotaoApp` sem `expande` e `SeloStatusApp` encolhem com reticências, e o `CartaoListaApp` limita o selo a 45% da linha (fonte grande não estoura o layout).
- Decisões de implementação:
  - "Em dia" no filtro = sem parcela atrasada (parcelas futuras não contam);
  - nascimento digitado (`DD/MM/AAAA`) em vez do calendário;
  - o cache de clientes é limpo quando a consultora sai (`RepositorioClientes` ouve o `RepositorioConsultora`).
- E2E-04 escrito, **não executado** (roda só antes de lançar).

## Workflow follow-up

- Aplicar a migração no Supabase remoto **somente após a confirmação do dono do projeto**.
- Arquivar com `/opsx:archive` depois da revisão.
