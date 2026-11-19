# perfil-da-consultora Specification

## Purpose
Permite à consultora ver e manter os próprios dados — nome, WhatsApp, foto e chave Pix — que aparecem no menu, nos comprovantes e nas mensagens às clientes.

## Requirements

### Requirement: Ver o perfil
O app SHALL mostrar, em Meu perfil: a foto (ou as iniciais), o nome, o WhatsApp formatado e a chave Pix com o tipo.

#### Scenario: Perfil completo
- **GIVEN** a consultora tem foto, WhatsApp 11987654321 e chave Pix do tipo telefone
- **WHEN** ela abre Meu perfil
- **THEN** aparecem a foto, o nome, "(11) 98765-4321" e a chave com o selo "Tipo: Telefone"

#### Scenario: Sem chave Pix
- **GIVEN** a consultora não cadastrou chave Pix
- **WHEN** ela abre Meu perfil
- **THEN** o lugar da chave mostra "Não cadastrada", sem o botão de copiar

### Requirement: Copiar a chave Pix
O app SHALL copiar a chave Pix para a área de transferência ao tocar no ícone de copiar, e MUST avisar que copiou.

#### Scenario: Copiar
- **WHEN** a consultora toca no ícone de copiar
- **THEN** a chave vai para a área de transferência e aparece o aviso "Chave Pix copiada"

### Requirement: Editar o perfil
O app SHALL permitir alterar o nome, o WhatsApp e o tipo e a chave Pix. Nome e WhatsApp são obrigatórios. Salvar MUST gravar os dados e voltar a Meu perfil já atualizado; cancelar MUST descartar as alterações.

#### Scenario: Salvar alterações
- **WHEN** a consultora muda o nome para "Ana Paula Silva" e salva
- **THEN** Meu perfil e o menu lateral passam a mostrar "Ana Paula Silva"

#### Scenario: Nome vazio
- **WHEN** a consultora apaga o nome e salva
- **THEN** o campo mostra "Informe o nome" e nada é gravado

#### Scenario: Cancelar
- **WHEN** a consultora altera o WhatsApp e toca em Cancelar
- **THEN** Meu perfil continua com o WhatsApp anterior

### Requirement: Validação da chave Pix pelo tipo
O app MUST validar a chave Pix conforme o tipo escolhido e MUST exigir os dois juntos: tipo e chave preenchidos, ou ambos vazios.

Regras por tipo:
- **Telefone:** DDD mais 8 ou 9 dígitos.
- **CPF:** 11 dígitos com dígitos verificadores válidos.
- **E-mail:** formato de e-mail.
- **Aleatória:** formato de chave aleatória (UUID).

#### Scenario: CPF inválido
- **GIVEN** o tipo escolhido é CPF
- **WHEN** a consultora informa "111.111.111-11" e salva
- **THEN** o campo mostra "CPF inválido" e nada é gravado

#### Scenario: Chave sem tipo
- **WHEN** a consultora informa uma chave sem escolher o tipo e salva
- **THEN** o tipo mostra "Escolha o tipo da chave" e nada é gravado

#### Scenario: Remover a chave
- **WHEN** a consultora apaga a chave, limpa o tipo e salva
- **THEN** o perfil fica sem chave Pix

### Requirement: Foto do perfil
O app SHALL permitir tirar uma foto com a câmera ou escolher uma da galeria (JPG ou PNG), sempre recortada em 1:1, e também remover a foto. A foto MUST ficar acessível somente à própria consultora.

#### Scenario: Escolher da galeria
- **WHEN** a consultora escolhe uma imagem da galeria e confirma o recorte
- **THEN** a nova foto aparece no perfil e no menu lateral

#### Scenario: Desistir no recorte
- **WHEN** a consultora cancela a tela de recorte
- **THEN** a foto anterior continua

#### Scenario: Remover foto
- **WHEN** a consultora toca em Remover foto
- **THEN** o perfil e o menu passam a mostrar as iniciais

#### Scenario: Falha no envio
- **GIVEN** a conexão cai durante o envio
- **WHEN** a consultora confirma a nova foto
- **THEN** aparece uma mensagem de erro e a foto anterior continua

### Requirement: Apagar a conta pedindo ao suporte
A folha "Opções da Conta" SHALL ter **Apagar Conta**, que MUST abrir o WhatsApp do suporte com a mensagem pronta `Quero apagar minha conta no app "Sou Consultora"`. O app MUST NOT apagar dados nem encerrar a sessão por conta própria: o pedido é atendido pelo suporte. Se o WhatsApp não puder ser aberto, o app MUST mostrar um aviso.

#### Scenario: Pedir a exclusão
- **GIVEN** a consultora está em Meu Perfil
- **WHEN** ela abre Mais opções e toca em **Apagar Conta**
- **THEN** o WhatsApp abre na conversa com o suporte, com a mensagem pronta, e ela continua logada

#### Scenario: WhatsApp indisponível
- **GIVEN** o aparelho não consegue abrir o WhatsApp
- **WHEN** ela toca em **Apagar Conta**
- **THEN** aparece "Não foi possível abrir o WhatsApp" e nada é apagado

