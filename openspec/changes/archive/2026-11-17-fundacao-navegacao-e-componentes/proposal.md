# Proposal

## Why

O banco está pronto, mas o app ainda abre direto no login e não tem para onde ir depois dele. Antes de construir qualquer fluxo da consultora, é preciso a estrutura comum a todas as telas: navegar entre os módulos, proteger o app de quem não está logado e ter os componentes visuais do design system prontos. Assim, cada fase seguinte só monta a sua tela, sem reinventar o cabeçalho, a lista ou o campo de valor.

## What Changes

- **Rotas do app.** Uma rota para cada módulo de `fluxos.md` (Início, Vendas, Clientes, Produtos, Serviços, Fornecedores, A receber, A pagar, Financeiro, Perfil). Os módulos ainda não construídos mostram um aviso de "em construção".
- **Barra inferior fixa com 5 itens:** Produtos, Clientes, **Início** (central, em destaque), Vendas e Financeiro. Ela aparece nas telas principais e some nas telas de detalhe e de formulário.
- **Menu lateral** com o mapa completo, nas seções do design: Navegação principal, Gestão financeira, Configurações e Sair da conta. O cabeçalho do menu mostra o nome e a foto da consultora.
- **Controle de acesso:**
  - sem sessão, o app sempre vai para o login;
  - com sessão, vai para o Início;
  - se a sessão terminar ou expirar, volta para o login.
- **Sair da conta** encerra a sessão no Supabase e no Google.
- **Componentes reutilizáveis do design system** em `ui/widgets/`:
  - cabeçalho;
  - campos com rótulo (texto, seleção, valor em R$, data, busca, quantidade);
  - alternador segmentado;
  - botão flutuante e botão de ícone;
  - card de lista e grupo de navegação;
  - foto 1:1;
  - folha inferior e diálogo de confirmação;
  - indicador de passos;
  - estados de vazio, carregando e erro.
- **Formatadores pt-BR** de moeda, data e telefone.
- **Login permanece em `ui/modules/login/`** (feature de uma tela só, sem pasta pai). A navegação pós-login deixa de ser responsabilidade da tela.
- **Fora do escopo:**
  - a tela de cadastro do WhatsApp e a checagem "tem registro de consultora?" (Fase 1);
  - os contadores do menu lateral (Fase 5);
  - o conteúdo real de cada módulo.

## Capabilities

### New Capabilities
- `navegacao-do-app`: como a consultora se move entre os módulos — barra inferior, menu lateral, telas principais vs. telas empilhadas e o comportamento do botão voltar.
- `controle-de-acesso`: quais telas cada situação de sessão pode ver, os redirecionamentos e a saída da conta.

### Modified Capabilities
<!-- Nenhuma. -->

## Impact

- **Dependências novas:**
  - `go_router` (rotas e redirecionamento por sessão);
  - `intl` (moeda e data pt-BR; já vem como dependência transitiva e passa a ser direta);
  - `package_info_plus` (versão do app no rodapé do menu).
- **Código:**
  - `lib/main.dart` passa a usar o roteador;
  - pasta nova `lib/ui/navegacao/` (rotas, casca com a barra inferior e o menu lateral);
  - widgets novos em `lib/ui/widgets/*`;
  - formatadores em `lib/ui/formatadores/`;
  - `core/api`, `core/service` e `core/repository` de autenticação ganham fluxo de sessão e saída.
- **Documentação:** `.claude/rules/architecture.md` e `CLAUDE.md` passam a citar `ui/navegacao/` e `ui/formatadores/`; `fluxos.md` registra a barra inferior fixa.
- **Testes:** widget tests de navegação e dos componentes; teste unitário da regra de redirecionamento.
