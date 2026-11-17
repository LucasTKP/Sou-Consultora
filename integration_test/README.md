# Testes E2E — Sou Consultora

Testes de ponta a ponta: abrem o **app de verdade**, ligado ao **Supabase real**, e percorrem as telas como a consultora faria.

> **Quando rodar:** a suíte inteira roda **só antes de lançar uma versão** (Play Store / App Store), porque é lenta.
> Durante o desenvolvimento, rode apenas o cenário da tarefa (veja "Rodar um cenário só").

---

## Antes de lançar: passo a passo

### 1. Entrar no app (obrigatório a cada rodada)

O login do Google/Apple é uma tela nativa que o teste não consegue operar. E, no iOS, o `flutter test` **desinstala o app ao terminar**, apagando a sessão. Por isso, **antes de cada rodada**:

```bash
flutter run -d <dispositivo>      # abre o app normal
# entre com Google ou Apple e feche o app (q no terminal)
```

> Use sempre a **mesma conta**: os testes editam o perfil dela e restauram os valores no final.

### 2. Rodar a suíte

```bash
flutter test integration_test/app_e2e_test.dart -d <dispositivo>
```

- **Dispositivos:** `flutter devices`. No simulador iOS, use o id (ex.: `3B326C6A-…`). No Android, o id do `adb devices`.
- **Conta nova (sem cadastro):** o cenário de primeiro acesso cadastra com o WhatsApp `11999990000`. Para usar outro número:
  `--dart-define=E2E_WHATSAPP=11988887777`
- **Se o app abrir no login,** o teste para com a mensagem *"O app abriu no login…"*. Volte ao passo 1.

### 3. Conferir à mão (o que o E2E não alcança)

Marque tudo antes de publicar:

- [ ] **Login com Google** (sair e entrar de novo) — a tela do Google é nativa.
- [ ] **Login com Apple** (no iPhone).
- [ ] **Sair da conta** pelo menu e pelo perfil — o E2E só abre a confirmação e **cancela**, para não perder a sessão.
- [ ] **Foto do perfil:** tirar foto com a câmera, escolher da galeria, recortar em 1:1 e remover — câmera, galeria e recorte são telas nativas.
- [ ] **Apagar conta:** hoje **não faz nada** (decisão de produto). **Obrigatório implementar antes da App Store.**

### 4. Se algo falhar

O erro mostra o cenário (ex.: `E2E-03 Perfil …`) e, nos tempos esgotados, a lista de textos que estavam na tela. Corrija, volte ao passo 1 e rode só o cenário que falhou.

---

## Rodar um cenário só

```bash
flutter test integration_test/app_e2e_test.dart -d <dispositivo> --plain-name "chave Pix"
```

`--plain-name` aceita qualquer parte do nome do cenário. O passo 1 (entrar no app) continua valendo.

---

## O que é coberto

| Código | Cenário | Observações |
|---|---|---|
| **E2E-01** | Com sessão salva, abre no Início ou no Cadastro (nunca no login) | |
| **E2E-01** | Primeiro acesso: WhatsApp inválido é recusado; o válido cadastra e abre o Início | Só roda em conta **sem cadastro**; nas demais aparece como *skipped* |
| **E2E-02** | Barra inferior abre os 5 módulos | |
| **E2E-02** | Menu lateral: nome da consultora, versão, navegar para Fornecedores | |
| **E2E-02** | Voltar do sistema numa tela principal leva ao Início | |
| **E2E-03** | Perfil mostra os dados e abre por cima (sem a barra); voltar retorna | |
| **E2E-03** | Editar o nome grava **no banco** (relido do Supabase) e atualiza o menu | Restaura o nome no fim |
| **E2E-03** | Chave Pix: CPF inválido é recusado; e-mail é salvo, exibido com o tipo e copiado | Restaura a chave no fim |
| **E2E-03** | Cancelar a edição não grava | |
| **E2E-03** | Folha da foto oferece câmera e galeria | O fluxo nativo é manual (passo 3) |
| **E2E-03** | Sair pede confirmação | O teste **cancela** |

### Dados que os testes alteram

- **Perfil** (nome, WhatsApp, chave Pix): os valores originais são guardados no início e **restaurados no fim de cada cenário, mesmo se ele falhar**.
- **Cadastro:** numa conta sem cadastro, o E2E-01 cria o registro (com `E2E_WHATSAPP`). Como "Apagar conta" ainda não funciona, o registro permanece.

---

## Para quem desenvolve

- **Arquivos:**
  - `app_e2e_test.dart`: os cenários, agrupados por código (`E2E-01`, `E2E-02`…);
  - `auxiliares_e2e.dart`: abrir o app, esperar pela rede (`esperarAte`), tocar, digitar e rolar.
- **Rede real:** use `esperarAte`/`esperarSumir` depois de ações que falam com o Supabase. O `pumpAndSettle` não espera requisições.
- **Cada fase nova** acrescenta o seu grupo (`E2E-04`…) e atualiza a tabela "O que é coberto" e o checklist manual. Execute **só o grupo novo** durante a tarefa.
- **Nunca:**
  - fazer logout num cenário (perde a sessão para o resto da suíte);
  - deixar dados alterados sem `addTearDown` para restaurar.
