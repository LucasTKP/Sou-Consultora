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
- [ ] **Abrir WhatsApp** nos Dados cadastrais da cliente abre a conversa certa (app externo).
- [ ] **Clientes no Android (percurso da 6.4, pendente):** botão **Novo cliente** aparece acima da barra inferior (corrigido sem conferir na tela); cadastrar com CEP real (preenche rua, bairro, cidade e UF); buscar; filtrar (contagens); editar e ver os Dados recarregados. Já conferido no emulador em 17/11/2026: cadastro sem endereço, detalhes, dados e Abrir WhatsApp.
- [ ] **WhatsApp do fornecedor** nos detalhes abre a conversa certa (app externo).
- [ ] **Fornecedores no aparelho (6.5 do change `fornecedores`):** cadastrar, buscar, filtrar por status, abrir detalhes, editar e colocar em espera.
- [ ] **Produtos no aparelho (6.5 do change `produtos`):** cadastrar com foto da **galeria** e da **câmera**, trocar e remover a foto, cadastrar uma marca pelo atalho ao lado de "Marca / Fornecedor" e escolhê-la, buscar, filtrar por marca/categoria e por estoque, ordenar por preço, abrir detalhes e editar.
- [ ] **Estoque no aparelho (5.5 do change `estoque`):** lançar pela lista (atalho **Lançar estoque**) e pelo produto, compra com produtos de duas marcas (cada lote com o fornecedor certo), margem prevista (Excelente/Boa/Baixa/Prejuízo), validade do lote, cancelar com itens (confirmação), **Cadastrar novo produto** no lançamento e apagar um lote sem vendas.
- [ ] **Serviços no aparelho (change `servicos`):** cadastrar com foto, filtrar por categoria, ordenar, conferir o retorno estimado enquanto preenche e editar.
- [ ] **Vendas no aparelho (change `vendas`):** venda com baixa de estoque (conferir o saldo e o lote mais antigo consumido), estoque insuficiente, venda de serviço, dividido em 3 com valores e datas editados (Faltam/Sobram), entrada paga, editar venda sem pagamento, Cobrar no WhatsApp (mensagem com Pix), cancelar devolvendo o estoque, Nova venda pela cliente e Compras da cliente.
- [ ] **A receber no aparelho (change `a-receber`):** filtros de status (contagens) e mês, "Todos os meses", busca por produto, ordenar por valor; detalhes de uma parcela atrasada ("Venceu em… há N dias") e de uma parcial (barra pago × resta); **Cobrar** abre o WhatsApp com a mensagem e o Pix; pagar parcial e depois quitar; valor acima do saldo é recusado; pagamento com **data de ontem** abre o comprovante desse pagamento; **Compartilhar** abre a folha do sistema com a imagem nítida e o texto curto (enviar no WhatsApp e conferir); **Gerar recibo** pelas opções; cancelar a venda pela parcela.
- [ ] **A pagar no aparelho (change `a-pagar`):** lançar com o atalho de cadastrar marca; filtros de status (contagens) e mês; busca pela observação; card atrasado em vermelho; pagar com a **data de ontem** ("Liquidado em" ontem); anexar comprovante por **foto da câmera**, **da galeria** e **PDF** (o seletor do sistema abre e só aceita PDF), **Ver comprovante** abre a imagem e o PDF; anexar outro substitui; desfazer pagamento; editar; excluir com comprovante; **Ver em A pagar** nos detalhes do fornecedor abre só a marca e, na volta, o resumo da marca está atualizado.
- [ ] **Financeiro no aparelho (change `financeiro`):** gráfico legível com 12 barras (mês escolhido em destaque com o valor em cima), trocar o período para um mês anterior (gráfico e cards mudam), registrar uma venda e pagar um boleto e voltar ao Financeiro (números atualizados sem puxar para recarregar), botão redondo do topo abre Nova venda.
- [ ] **Início no aparelho (change `inicio`):** cumprimento pela hora com a foto; os três números abrem Vendas, A receber (em Pago) e A pagar; alertas de boleto (venceu, hoje, amanhã) com Ver fatura; Vendas atrasadas com Cobrar agora (A receber em Atrasado); lembrete de recompra de um produto com duração prevista (comprar há mais de duração − 7 dias) com o ícone do WhatsApp abrindo a mensagem pronta; Ver todos abre Clientes; selo de atrasadas no menu lateral; o print `build/prints_e2e/e2e13-inicio.png` legível (botões sem corte).
- [ ] **Versão mínima no aparelho (change `versao-minima`):** no painel do Supabase, subir `versao_minima_android` (ou `_ios`) para uma versão acima da instalada (ex.: `99.0.0`) e abrir o app **sem sessão** e **com sessão**: aparece "Atualização necessária", o voltar do sistema não entra no app e **Atualizar agora** abre a loja (preencher `URL_LOJA_ANDROID`/`URL_LOJA_IOS` no `.env` e rodar `dart run build_runner build`). Voltar o valor para `1.0.0` e conferir que o app abre normal.
- [ ] **Marcas no cadastro (conta nova):** na tela de cadastro, marcar Natura e Mary Kay (e desmarcar uma para ver o chip alternar), concluir e conferir em Fornecedores que só as marcadas existem, com o ramo preenchido. Repetir sem marcar nenhuma. O E2E-01 de primeiro acesso não marca marcas, para não criar fornecedores extras na conta de teste.
- [ ] **CEP sem internet:** com o aparelho offline, digitar o CEP avisa e deixa preencher à mão.
- [ ] **Apagar conta:** hoje **não faz nada** (decisão de produto). **Obrigatório implementar antes da App Store.**

### 4. Se algo falhar

O erro mostra o cenário (ex.: `E2E-03 Perfil …`) e, nos tempos esgotados, a lista de textos que estavam na tela. Corrija, volte ao passo 1 e rode só o cenário que falhou.

---

## Rodar um grupo sem perder a sessão (recomendado durante a tarefa)

Com `--keep-app-running`, o `flutter drive` **não desinstala** o app no fim: entra-se com Google/Apple uma vez e roda-se quantas vezes precisar. **Sem essa flag, o app é desinstalado ao terminar e a sessão se perde** (é preciso entrar de novo antes da próxima rodada).

```bash
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_e2e_test.dart \
  -d <dispositivo> --keep-app-running --dart-define=E2E_GRUPO=E2E-04
```

`E2E_GRUPO` escolhe o grupo (os outros aparecem como *skipped*); sem ele, roda todos.

## Prints dos cenários

Com o `flutter drive`, os cenários que chamam `binding.takeScreenshot('<nome>')` salvam a imagem em `build/prints_e2e/<nome>.png` (ex.: o E2E-13 guarda o Início com os alertas).

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
| **E2E-04** | Clientes: cadastra com CEP real (só na 1ª vez), busca, abre detalhes e dados por cima | Cliente fixa "E2E Cliente" (WhatsApp 11999990001) |
| **E2E-04** | Editar as observações grava no banco (relido) | Restaura as observações no fim |
| **E2E-05** | Fornecedores: cadastra (só na 1ª vez), busca, abre detalhes por cima, sem botão de excluir | Fornecedor fixo "E2E Fornecedor" (telefone 11999990002) |
| **E2E-05** | Colocar em espera grava no banco (relido) | Volta a ativo no fim |
| **E2E-06** | Produtos: cadastra em 2 passos (só na 1ª vez, sem foto), aparece "Esgotado", busca pelo código, abre detalhes por cima, sem botão de excluir | Produto fixo "E2E Produto" (código E2E-001), marca "E2E Fornecedor" |
| **E2E-06** | Editar o preço grava no banco (relido) | Restaura o preço no fim |
| **E2E-07** | Estoque: lança 2 unidades do "E2E Produto" pela aba Estoque; o lote (quantidade, custo e fornecedor) é relido do banco e o saldo sobe | Apaga o lote no fim (o produto volta a "Esgotado"). Depende do E2E-06 |
| **E2E-08** | Serviços: cadastra (só na 1ª vez), abre os detalhes com o retorno estimado, sem botão de excluir; editar o preço grava no banco (relido) | Serviço fixo "E2E Serviço" (Unhas); restaura o preço no fim |
| **E2E-09** | Vendas: registra uma encomenda à vista do "E2E Produto" para a "E2E Cliente", relê do banco (cliente, item sem baixa) e cancela pela tela (Mais opções → Cancelar venda) | Depende do E2E-04 e do E2E-06; a venda é sempre cancelada no fim |
| **E2E-10** | A receber: venda do "E2E Serviço" em 2x (1ª vence hoje) criada pelo repositório; pelo menu abre A receber, busca a cliente, abre a 1ª parcela e paga **metade** pela folha; relê do banco (um pagamento, saldo = o resto); o comprovante mostra "Parcela 1 de 2 • Parcial" e o saldo da venda; volta aos detalhes e cancela a venda pela tela | Depende do E2E-04 e do E2E-08; a venda é sempre cancelada no fim. O compartilhar nativo é manual (passo 3) |
| **E2E-11** | A pagar: pelo menu, lança pela tela um boleto do "E2E Fornecedor" (R$ 123,45, vence hoje, com observação); relê do banco; abre pela busca da observação, **Confirmar pagamento** com a data de hoje (relido: pago hoje), **Desfazer pagamento** (relido: em aberto) e **Excluir boleto** (relido: não existe) | Depende do E2E-05; o boleto é sempre excluído no fim. Câmera, galeria e PDF do comprovante são manuais (passo 3) |
| **E2E-12** | Financeiro: cria pelo repositório uma venda do "E2E Serviço" e um boleto de R$ 43,21 do "E2E Fornecedor" no mês atual; o banco sobe exatamente esses valores; pela barra, o Financeiro abre no mês atual com o total dos 12 meses, o "Faturamento no mês" e as "Despesas no mês" iguais ao cálculo sobre o banco; A Receber e A Pagar abrem os módulos | Depende do E2E-04, E2E-05 e E2E-08; a venda é cancelada e o boleto excluído no fim |
| **E2E-13** | Início: cria pelo repositório uma venda de hoje do "E2E Serviço" com a parcela vencida há 3 dias e um boleto de R$ 84,25 do "E2E Fornecedor" que vence amanhã; o banco sobe exatamente esses valores; o Início mostra o Vendido no mês, "VENCE AMANHÃ", as Vendas Atrasadas (clientes e total) iguais ao cálculo sobre o banco e tira o print `build/prints_e2e/e2e13-inicio.png`; **Cobrar agora** abre A receber em Atrasado e Todos os meses | Depende do E2E-04, E2E-05 e E2E-08; a venda é cancelada e o boleto excluído no fim |
| **E2E-14** | Versão mínima: o banco (Supabase real, lido pelo app) expõe `versao_minima_android` e `versao_minima_ios`; a versão instalada passa pelo portão e a tela "Atualização necessária" não aparece | Só leitura. O bloqueio em si (versão abaixo do mínimo) é coberto por testes de unidade e pelo checklist manual |

### Dados que os testes alteram

- **Perfil** (nome, WhatsApp, chave Pix): os valores originais são guardados no início e **restaurados no fim de cada cenário, mesmo se ele falhar**.
- **Fornecedores:** o fornecedor "E2E Fornecedor" é criado uma única vez e reaproveitado (o app não apaga fornecedores). O status em espera é desfeito no fim.
- **Produtos:** o produto "E2E Produto" é criado uma única vez e reaproveitado (o app não apaga produtos). O preço alterado volta ao original no fim. Se o E2E-05 ainda não rodou, o E2E-06 cria a marca "E2E Fornecedor".
- **Estoque:** o E2E-07 lança um lote no "E2E Produto" e o apaga no fim; o produto continua "Esgotado" entre as rodadas.
- **A receber:** o E2E-10 cria uma venda do "E2E Serviço" em 2x, registra um pagamento e cancela a venda no fim (cancelar apaga parcelas e pagamentos). Não mexe no estoque.
- **Início:** o E2E-13 cria uma venda atrasada do "E2E Serviço" e um boleto do "E2E Fornecedor" e os apaga no fim.
- **Financeiro:** o E2E-12 cria uma venda do "E2E Serviço" e um boleto do "E2E Fornecedor" e os apaga no fim.
- **A pagar:** o E2E-11 lança um boleto do "E2E Fornecedor", paga, desfaz e o exclui no fim (sem comprovante).
- **Clientes:** a cliente "E2E Cliente" é criada uma única vez e reaproveitada (o app não apaga clientes). As observações editadas são restauradas.
- **Cadastro:** numa conta sem cadastro, o E2E-01 cria o registro (com `E2E_WHATSAPP`). Como "Apagar conta" ainda não funciona, o registro permanece.

---

## Para quem desenvolve

- **Arquivos:**
  - `app_e2e_test.dart`: os cenários, agrupados por código (`E2E-01`, `E2E-02`…);
  - `auxiliares_e2e.dart`: abrir o app, esperar pela rede (`esperarAte`), tocar, digitar e rolar.
- **Rede real:** use `esperarAte`/`esperarSumir` depois de ações que falam com o Supabase. O `pumpAndSettle` não espera requisições.
- **Cada fase nova** acrescenta o seu grupo (`E2E-05`…) e atualiza a tabela "O que é coberto" e o checklist manual. Execute **só o grupo novo** durante a tarefa.
- **Nunca:**
  - fazer logout num cenário (perde a sessão para o resto da suíte);
  - deixar dados alterados sem `addTearDown` para restaurar.
