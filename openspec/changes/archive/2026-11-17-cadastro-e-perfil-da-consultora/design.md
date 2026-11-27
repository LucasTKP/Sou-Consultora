# Design

## Context

- **Banco:**
  - `consultoras` já existe, com RLS, `id = auth.uid()` e sem policy de delete;
  - `apagar_minha_conta()` já existe;
  - o bucket privado `fotos` aceita só a pasta `<uid>/`.
- **Navegação:**
  - `NotificadorSessao` conhece só "logado" ou "não logado";
  - `destinoPermitido` decide entre login e Início;
  - `/perfil` é uma rota "em construção" dentro do shell.
- **Resumo do menu:** `ResumoConsultora` vem dos metadados do Google ou da Apple.
- **Validação:** fica no Cubit e no Model, e o widget só exibe o `erro` (regra em `.claude/rules/dart.md`).
- Motivação: `proposal.md`. Comportamento: `specs/`.

## Goals / Non-Goals

**Goals:**
- Um único ponto de verdade sobre a situação de acesso (sessão + cadastro), testável sem Flutter.
- Os dados da consultora carregados uma vez e compartilhados entre o menu, o perfil e as fases seguintes.

**Non-Goals:**
- Uso do nome e da chave Pix no comprovante (Fase 5).
- Selos "Revendedora Diamante" e "Ativa".

## Decisions

### 1. `EstadoAcesso` substitui o booleano de sessão
`NotificadorSessao` vira `NotificadorAcesso` e expõe um `EstadoAcesso`:

| Estado | Quando |
|---|---|
| `desconectado` | sem sessão |
| `verificando` | sessão começou; buscando `consultoras` |
| `erroVerificacao` | a busca falhou (rede) |
| `semCadastro` | sessão sem linha em `consultoras` |
| `pronto` | sessão com cadastro |

- Métodos: `tentarNovamente()` (refaz a busca) e `cadastroConcluido()` (vai para `pronto` sem nova consulta).
- **Por quê:** o roteador lê um único valor, e a regra continua sendo uma função pura:

  ```
  destinoPermitido(estado, destino):
    desconectado                  → /login
    verificando | erroVerificacao → /carregando
    semCadastro                   → /cadastro
    pronto + (/login | /cadastro | /carregando) → /inicio
  ```

  Fora desses casos, a rota pedida é permitida.

### 2. Rotas novas
- `/carregando`: logo, indicador e, no estado de erro, mensagem com "Tentar novamente".
- `/cadastro`: `ui/modules/cadastro/`.
- `/perfil` sai do shell e passa a abrir **por cima** (`parentNavigatorKey: chaveRaiz`, sem a barra), porque o design de Meu perfil tem a seta de voltar e não tem a barra. O menu passa a usar `push` para Perfil e Configurações, então voltar retorna à tela de onde saiu.
- `/perfil/editar` também abre por cima.

### 3. Camadas da consultora

| Camada | Arquivo | Responsabilidade |
|---|---|---|
| DTO | `core/dto/consultora_dto.dart` | espelho de `consultoras` (`fromJson`/`toJson`) + `paraModel()` |
| Model | `core/model/consultora.dart` | `Consultora` (nome, whatsapp em dígitos, `ChavePix?`, caminho e URL assinada da foto) e as regras: `validarNome`, `validarWhatsapp` |
| Model | `core/model/chave_pix.dart` | `TipoChavePix` (telefone, cpf, email, aleatoria) + `ChavePix.validar(tipo, texto)` → mensagem ou null; normalização e formatação |
| Service | `core/service/servico_consultora.dart` | select/insert/update em `consultoras`; upload, remoção e URL assinada no Storage |
| Service | `core/service/servico_foto_dispositivo.dart` | `image_picker` + `image_cropper` → `Uint8List?` (null = cancelou) |
| Repository | `core/repository/repositorio_consultora.dart` | `buscarMinha`, `cadastrar`, `atualizar`, `escolherFoto`, `trocarFoto`, `removerFoto`; mantém a `Consultora` atual e emite `Stream<Consultora?>` |

- O cubit da casca assina essa stream, então o menu atualiza sozinho depois de editar o perfil.
- `ResumoConsultora` ganha `ResumoConsultora.daConsultora(Consultora)`.

### 4. `core/api` continua fino
`ApiSupabase` ganha só portas genéricas:
- `tabela(String)`;
- `rpc(String, {params})`;
- `armazenamento` (Storage);
- `idUsuario`.

O service monta as consultas. Exceções (`PostgrestException`, `StorageException`, `SocketException`, `ClientException`) viram `FalhaRede` ou `FalhaInesperada` no service, e nunca chegam ao Cubit.

### 5. Normalização dos dados

| Dado | Como é guardado |
|---|---|
| WhatsApp | só dígitos (10 ou 11), com CHECK no banco |
| Pix telefone | `+55` + dígitos (padrão do Banco Central) |
| Pix CPF | 11 dígitos |
| Pix e-mail | minúsculas |
| Pix aleatória | UUID em minúsculas |

- A exibição formata cada valor.
- O CHECK do banco garante que tipo e chave existam juntos.
- A validação de formato fica no Model, para dar uma mensagem amigável ao usuário.

### 6. Foto
- **Seleção:** `image_picker` com `maxWidth: 1024` e `imageQuality: 85`, depois `image_cropper` com `aspectRatio 1:1` e textos em pt-BR.
- **Envio:** para `fotos/<uid>/perfil-<timestamp>.jpg`. Em seguida, atualiza `consultoras.foto_url` com o **caminho** (não a URL) e apaga o arquivo anterior.
  - **Por que um nome novo a cada envio:** evita que o app mostre a foto antiga guardada em cache.
- **Exibição:** por URL assinada de 1 hora, gerada no repositório ao carregar.
- **Remover:** apaga o arquivo e grava `foto_url = null`.

### 7. Apagar conta fora desta change
- O item aparece na folha Opções da conta, mas **não faz nada**, por decisão do dono do projeto.
- Quando for implementado, a ordem será: remover os arquivos de `<uid>/` primeiro; depois chamar `apagar_minha_conta()`, porque, sem o usuário, o RLS do Storage impede a remoção; e por fim sair.
- **É obrigatório antes de publicar na App Store.**

### 8. Cadastro: nome condicional
- `CadastroCubit` recebe o nome sugerido (`RepositorioAutenticacao.resumoDaConsultora().nome`).
- Se o nome sugerido estiver vazio ou for o e-mail (fallback), a tela mostra o campo nome.
- Voltar chama `RepositorioAutenticacao.sair()`.

### 9. Telas
- `ui/modules/cadastro/`: `cadastro_state`, `cadastro_cubit` e `cadastro_screen`.
- `ui/modules/perfil/meu_perfil/`: os 3 arquivos + `widgets/` com a linha de dado (rótulo, valor, ícone colorido, ação) e as folhas de opções da conta e da foto.
- `ui/modules/perfil/editar/`: os 3 arquivos.
- A folha de foto é aberta tanto do perfil (ícone da câmera) quanto da edição ("Alterar foto"). Ela fica em `ui/modules/perfil/widgets/`, compartilhada pelas duas telas do mesmo módulo.

### 10. Dependências nativas
- **iOS (`Info.plist`):** `NSCameraUsageDescription` e `NSPhotoLibraryUsageDescription`, com textos em pt-BR.
- **Android (`AndroidManifest.xml`):** `UCropActivity` do `image_cropper`.

## Risks / Trade-offs

- **[Apagar conta inativo]** → Bloqueia a publicação na App Store até ser implementado; registrado aqui e na proposta.
- **[A URL assinada expira em 1 hora com o app aberto]** → O repositório renova a URL ao recarregar a consultora. Imagem quebrada cai nas iniciais (`AvatarApp`).
- **[Câmera e recorte não rodam em widget test]** → `ServicoFotoDispositivo` fica atrás de uma interface, com uma versão falsa nos testes. O fluxo real é conferido no simulador.
- **[Consultoras antigas sem cadastro, como os seus logins de teste]** → Caem em `semCadastro` e fazem o cadastro normalmente.

## Migration Plan

1. Criar a migração `..._consultora_formatos.sql` e verificar com `supabase db reset` e `supabase test db`.
2. Aplicar no remoto com `supabase db push`, **com a confirmação do dono do projeto**. Não existem linhas em `consultoras` ainda, então os CHECKs não conflitam.
