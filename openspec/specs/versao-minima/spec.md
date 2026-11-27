# versao-minima Specification

## Purpose
Obriga a atualização do app quando a versão instalada é mais antiga que a mínima definida no banco, por plataforma (Android e iOS), antes mesmo do login.

## Requirements

### Requirement: Tabela de configurações com a versão mínima
O banco SHALL ter a tabela `configuracoes` (colunas `chave` e `valor`) com as chaves `versao_minima_android` e `versao_minima_ios`, no formato `maior.menor.correção`. Qualquer pessoa, logada ou não, MUST poder ler a tabela, e ninguém MUST poder gravar nela pelo app. A tabela MUST NOT guardar dado de consultora nem segredo.

#### Scenario: Leitura sem login
- **GIVEN** não há sessão ativa
- **WHEN** o app lê `configuracoes`
- **THEN** as duas versões mínimas são devolvidas

#### Scenario: Gravação pelo app
- **GIVEN** qualquer pessoa, logada ou não
- **WHEN** o app tenta inserir, alterar ou apagar uma linha de `configuracoes`
- **THEN** o banco recusa

### Requirement: Versão abaixo do mínimo bloqueia o app
O app MUST conferir a versão instalada contra o mínimo da própria plataforma ao abrir, antes do login, e MUST mostrar somente a tela "Atualização necessária" quando a versão for menor que o mínimo. A comparação SHALL usar `maior.menor.correção` numericamente e ignorar o número de build.

#### Scenario: Versão abaixo do mínimo sem sessão
- **GIVEN** a versão instalada é `1.0.0` e o mínimo da plataforma é `1.1.0`
- **WHEN** o app abre sem sessão
- **THEN** a tela "Atualização necessária" aparece no lugar do login

#### Scenario: Versão abaixo do mínimo com sessão
- **GIVEN** a consultora tem sessão e cadastro e a versão está abaixo do mínimo
- **WHEN** o app abre
- **THEN** a tela "Atualização necessária" aparece e nenhuma tela interna abre

#### Scenario: Versão igual ou acima do mínimo
- **GIVEN** a versão instalada é igual ou maior que o mínimo
- **WHEN** o app abre
- **THEN** o app segue o fluxo normal de acesso

#### Scenario: Cada plataforma usa o seu mínimo
- **GIVEN** `versao_minima_android` é `2.0.0` e `versao_minima_ios` é `1.0.0`
- **WHEN** a versão `1.5.0` abre no Android e no iOS
- **THEN** só o Android é bloqueado

### Requirement: Botão para a loja
A tela de atualização SHALL ter o botão "Atualizar agora", que abre a página do app na loja da plataforma, cujos links vêm das variáveis `URL_LOJA_ANDROID` e `URL_LOJA_IOS` do ambiente. Link ausente ou inválido MUST mostrar erro em toast sem fechar a tela.

#### Scenario: Abrir a loja
- **GIVEN** a tela de atualização está aberta
- **WHEN** a consultora toca em "Atualizar agora"
- **THEN** a página do app na loja da plataforma abre

### Requirement: Falha na conferência não trava o app
Se a versão mínima não puder ser lida (sem rede, tabela indisponível) ou estiver ilegível, o app SHALL seguir o fluxo normal em vez de bloquear.

#### Scenario: Sem internet ao conferir
- **GIVEN** o aparelho está sem internet
- **WHEN** o app abre
- **THEN** o app não mostra a tela de atualização e segue o fluxo normal de acesso
