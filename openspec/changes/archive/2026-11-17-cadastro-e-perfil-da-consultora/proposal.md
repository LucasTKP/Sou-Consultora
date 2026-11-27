# Proposal

## Why

Hoje qualquer pessoa que entra com Google ou Apple cai direto no Início, sem registro em `consultoras`. Nada nas próximas fases funciona sem esse registro: cada cliente, produto e venda pertence a uma consultora. Além disso, o comprovante enviado às clientes (Fase 5) precisa do nome e da chave Pix dela.

## What Changes

- **Cadastro (`acesso/02-cadastro.png`):**
  - logo depois do primeiro login, o app pede o WhatsApp com DDD e cria o registro da consultora;
  - o nome vem do Google ou da Apple; quando o provedor não informa o nome, a tela também o pede;
  - voltar no cadastro encerra a sessão e volta ao login.
- **Controle de acesso** passa a ter três situações:
  - sem sessão → login;
  - com sessão e sem cadastro → cadastro;
  - com cadastro → app.

  Enquanto o app confere o cadastro, aparece uma tela de carregamento com a marca. Se faltar internet nesse momento, ela oferece "Tentar novamente".
- **Meu perfil (`perfil/01`):** foto ou iniciais, nome, WhatsApp e chave Pix com tipo e botão de copiar. Também tem **Editar perfil** e **Mais opções**.
- **Editar perfil (`perfil/02`):** nome e WhatsApp obrigatórios; tipo e chave Pix opcionais, com validação por tipo (telefone, CPF, e-mail, aleatória).
- **Foto do perfil (`perfil/04`):** tirar foto, escolher da galeria (com recorte 1:1) ou remover. A foto fica no bucket privado `fotos/<id>/` e aparece por link temporário.
- **Opções da conta (`perfil/03`):**
  - **Sair da conta**, com o mesmo fluxo do menu lateral;
  - **Apagar conta** aparece, mas **ainda não faz nada** (decisão do dono do projeto). Precisa funcionar antes da publicação na App Store, que exige essa função.
- **Menu lateral:** o nome e a foto passam a vir do registro da consultora, e não mais do Google.
- **Banco:**
  - o WhatsApp da consultora é guardado só com dígitos (10 ou 11);
  - chave Pix e tipo só existem juntos (os dois preenchidos ou os dois vazios).
- **Fora do escopo:** os selos "Revendedora Diamante" e "Ativa" que aparecem ao fundo de `perfil/03` (não existem nos dados nem nas outras telas do perfil).

## Capabilities

### New Capabilities
- `perfil-da-consultora`: ver e editar os dados da consultora (nome, WhatsApp, foto e chave Pix), com as regras de validação e o recorte da foto.

### Modified Capabilities
- `controle-de-acesso`: com sessão, o destino passa a depender de existir o cadastro da consultora; entra a tela de cadastro e a verificação com carregamento e erro.

## Impact

- **Dependências novas:** `image_picker` (câmera e galeria) e `image_cropper` (recorte 1:1). Exigem descrições de uso da câmera e das fotos no `Info.plist` e a atividade de recorte no `AndroidManifest`.
- **Banco:** migração com os CHECKs de WhatsApp e do par Pix, e testes pgTAP.
- **Core:**
  - `core/dto/consultora_dto.dart` e `core/model/consultora.dart`;
  - `core/service/servico_consultora.dart` e `core/repository/repositorio_consultora.dart`;
  - `core/api` ganha leitura, gravação, Storage e RPC;
  - `ResumoConsultora` passa a ser montado a partir de `Consultora`.
- **UI:**
  - `ui/modules/cadastro/`;
  - `ui/modules/perfil/{meu_perfil,editar}/`;
  - `ui/navegacao/` (estado de acesso, rota `/cadastro`, tela de carregamento);
  - a rota `/perfil` deixa de ser "em construção".
