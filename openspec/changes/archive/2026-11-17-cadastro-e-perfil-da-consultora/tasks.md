# Tasks

## 1. Banco

- [x] 1.1 Criar a migração `..._consultora_formatos.sql`:
  - `whatsapp ~ '^\d{10,11}$'`;
  - `(chave_pix is null) = (tipo_chave_pix is null)`.

  Acrescentar casos em `supabase/tests/03_integridade.sql` e verificar com `supabase db reset && supabase test db` passando.

## 2. Model e DTO

- [x] 2.1 Criar `core/model/chave_pix.dart` (`TipoChavePix`, validar, normalizar, formatar); verificar com teste unitário cobrindo telefone, CPF válido e inválido (inclusive repetidos), e-mail, UUID e o par tipo/chave
- [x] 2.2 Criar `core/model/consultora.dart` (`validarNome`, `validarWhatsapp`, `whatsappFormatado`) e `ResumoConsultora.daConsultora`; verificar com teste unitário
- [x] 2.3 Criar `core/dto/consultora_dto.dart` com `fromJson`, `toJson` e `paraModel`; verificar com teste unitário de ida e volta

## 3. Api, services e repositório

- [x] 3.1 Em `core/api/api_supabase.dart`, expor `tabela`, `rpc`, `armazenamento` e `idUsuario`; verificar com `flutter analyze`
- [x] 3.2 Criar `core/service/servico_consultora.dart` (buscar, criar, atualizar, enviar, remover e assinar foto) com mapeamento de exceções para `FalhaApp`; verificar com teste unitário usando api falsa (sucesso e falha de rede)
- [x] 3.3 Criar `core/service/servico_foto_dispositivo.dart` (interface + implementação com `image_picker` e `image_cropper`); adicionar as dependências e as configurações nativas (`Info.plist`, `AndroidManifest`); verificar com `flutter build ios --simulator`
- [x] 3.4 Criar `core/repository/repositorio_consultora.dart` com cache e `Stream<Consultora?>`, e registrar os itens novos no `injetor`; verificar com teste unitário (cadastrar emite, trocar foto envia e apaga a anterior)

## 4. Acesso e navegação

- [x] 4.1 Criar `EstadoAcesso` e `NotificadorAcesso` (substituindo `NotificadorSessao`) e atualizar `destinoPermitido`; verificar com teste unitário de todas as linhas da tabela do design e da transição verificando → erro → tentar novamente → pronto
- [x] 4.2 Criar as rotas `/carregando` e `/cadastro`, mover `/perfil` (e `/perfil/editar`) para fora do shell e trocar Perfil e Configurações do menu para `push`; verificar com os testes de navegação atualizados
- [x] 4.3 Ligar o cubit da casca à stream do `RepositorioConsultora`; verificar com widget test (editar o nome atualiza o menu)

## 5. Cadastro

- [x] 5.1 Criar `ui/modules/cadastro/` (state, cubit, screen) com o campo de nome condicional e o voltar que encerra a sessão; verificar com testes do cubit (válido, inválido, falha de rede mantém os dados) e widget test (campo nome só aparece sem nome do provedor)

## 6. Perfil

- [x] 6.1 Criar `ui/modules/perfil/meu_perfil/` (dados, copiar Pix com aviso, folha Opções da conta com Sair e Apagar conta sem ação); verificar com widget test (perfil completo, sem Pix, copiar, sair confirmado)
- [x] 6.2 Criar `ui/modules/perfil/editar/` (nome, WhatsApp, tipo e chave Pix, salvar e cancelar); verificar com testes do cubit (nome vazio, CPF inválido, chave sem tipo, remover chave, salvar emite sucesso)
- [x] 6.3 Criar a folha Foto do perfil (tirar, galeria, remover) em `ui/modules/perfil/widgets/`; verificar com widget test usando serviço falso (cancelar no recorte mantém a foto, falha no envio mostra erro)

## 7. Integração e documentação

- [x] 7.1 Atualizar `../fluxos.md` (cadastro condicional, tela de carregamento, Perfil por cima) e `../banco-de-dados.md` (formatos de WhatsApp e Pix); verificar a consistência com as specs
- [x] 7.2 Rodar `flutter analyze` e `flutter test` e verificar zero problemas novos e todos os testes passando
- [x] 7.3 Rodar no simulador: primeiro login → cadastro → Início; perfil, editar e foto (galeria + recorte); registrar o resultado
  - 17/11: build iOS ok com `image_picker`/`image_cropper`; no simulador, ligado ao Supabase **real**, a sessão salva sem cadastro abriu a tela de cadastro (consulta com RLS funcionando). **Falta o percurso manual** (concluir o cadastro, perfil, editar, foto) pelo dono do projeto.
  - 17/11: percurso manual feito pelo dono do projeto no simulador: ok. Ajuste pedido no teste: botões mais altos (56) com texto 17 no tema Shad, e títulos de seção maiores via `TituloSecaoApp` (ícone 30, texto 24). E2E não executado nesta fase (decisão do dono).

## Resultado

- `supabase test db`: **98 testes** (4 novos de formato da consultora).
- `flutter test`: **118 testes** (core 34, formatadores 10, widgets 19, navegação + acesso 36, perfil 19).
- `flutter analyze`: só o aviso antigo de `ui/temas/tipografia_app.dart`.
- Correções encontradas pelos testes: o título "Recebimento via Pix" estourava a linha com fonte grande, e o selo da câmera ganhou tooltip (acessibilidade).
- Ambiente local: o `supabase link` gravou em `supabase/.temp/` versões do servidor remoto que quebram o CLI 2.54 local. Os arquivos foram movidos e o ambiente foi recriado. Atualizar o CLI para a 3.x evita o problema.

## Workflow follow-up

- Aplicar a migração no Supabase remoto **somente após a confirmação do dono do projeto**.
- Arquivar a change com `/opsx:archive` depois da revisão.
