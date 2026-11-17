// ignore_for_file: deprecated_member_use
//
// Testes E2E do Sou Consultora — rodam no app real, contra o Supabase real.
// Como rodar e o que conferir à mão: integration_test/README.md
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/model/fornecedor.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/core/repository/repositorio_estoque.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';

import 'auxiliares_e2e.dart';

/// Fornecedor fixo dos grupos E2E-05 e E2E-06 (o mesmo dado nos dois).
final fornecedorE2e = Fornecedor(
  nome: 'E2E Fornecedor',
  ramo: 'Teste automatizado',
  telefone: '11999990002',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ————————————————————————————————————————————————————————————————
  // E2E-01 · Acesso
  // ————————————————————————————————————————————————————————————————
  group('E2E-01 Acesso', () {
    testWidgets(
      'com sessão salva, abre no Início ou no Cadastro (nunca no login)',
      (tester) async {
        await abrirApp(tester);
        expect(find.text('Continuar com Google'), findsNothing);
      },
    );

    testWidgets(
      'primeiro acesso: WhatsApp inválido é recusado e o válido cadastra',
      (tester) async {
        await abrirApp(tester);
        if (find.text('Qual é o seu número?').evaluate().isEmpty) {
          markTestSkipped(
            'Conta já cadastrada — cenário de primeiro acesso não se aplica.',
          );
          return;
        }

        await digitar(tester, 'Número de WhatsApp', '119876');
        await tocar(tester, find.text('Continuar'));
        expect(find.text('Informe o WhatsApp com DDD'), findsOneWidget);

        await digitar(tester, 'Número de WhatsApp', whatsappE2E);
        await tocar(tester, find.text('Continuar'));
        await esperarAte(
          tester,
          find.text('Início'),
          descricao: 'Início após o cadastro',
        );
        expect(injetor<RepositorioConsultora>().atual?.whatsapp, whatsappE2E);
      },
    );
  }, skip: pularGrupo('E2E-01'));

  // ————————————————————————————————————————————————————————————————
  // E2E-02 · Navegação
  // ————————————————————————————————————————————————————————————————
  group('E2E-02 Navegação', () {
    testWidgets('barra inferior abre os 5 módulos', (tester) async {
      await abrirApp(tester);
      for (final modulo in [
        'Produtos',
        'Clientes',
        'Vendas',
        'Financeiro',
        'Início',
      ]) {
        await tester.tap(find.bySemanticsLabel(modulo).last);
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(Material, modulo),
          findsWidgets,
          reason: modulo,
        );
      }
    });

    testWidgets('menu lateral: consultora, item atual e navegação', (
      tester,
    ) async {
      await abrirApp(tester);
      final consultora = injetor<RepositorioConsultora>().atual!;

      await abrirMenu(tester);
      expect(find.text(consultora.nome), findsWidgets);
      expect(find.textContaining('Sou Consultora v'), findsOneWidget);

      await tocarNoMenu(tester, 'Fornecedores & Marcas');
      expect(find.byType(Drawer), findsNothing);
      expect(find.text('Fornecedores'), findsWidgets);
    });

    testWidgets('voltar do sistema: tela principal → Início', (tester) async {
      await abrirApp(tester);
      await tester.tap(find.bySemanticsLabel('Vendas').last);
      await tester.pumpAndSettle();

      await voltarDoSistema(tester);
      expect(find.text('Início'), findsWidgets);
    });
  }, skip: pularGrupo('E2E-02'));

  // ————————————————————————————————————————————————————————————————
  // E2E-03 · Perfil (restaura os dados originais no fim, mesmo se falhar)
  // ————————————————————————————————————————————————————————————————
  group('E2E-03 Perfil', () {
    late Consultora original;

    Future<void> abrirPerfil(WidgetTester tester) async {
      await abrirApp(tester);
      original = injetor<RepositorioConsultora>().atual!;
      addTearDown(
        () => injetor<RepositorioConsultora>().atualizar(
          nome: original.nome,
          whatsapp: original.whatsapp,
          chavePix: original.chavePix,
        ),
      );
      await abrirMenu(tester);
      await tocar(tester, find.text('Ver perfil'));
      await esperarAte(tester, find.text('Meu Perfil'));
    }

    Future<void> salvar(WidgetTester tester) async {
      await tocar(tester, find.text('Salvar Alterações'));
      await esperarAte(
        tester,
        find.text('Meu Perfil'),
        descricao: 'volta ao perfil após salvar',
      );
    }

    testWidgets('mostra os dados e abre por cima (sem a barra)', (
      tester,
    ) async {
      await abrirPerfil(tester);
      expect(find.text(original.nome), findsWidgets);
      expect(find.text('Editar Perfil'), findsOneWidget);
      expect(find.bySemanticsLabel('Produtos'), findsNothing);

      await tocar(tester, find.byTooltip('Voltar'));
      expect(find.bySemanticsLabel('Produtos'), findsWidgets);
    });

    testWidgets('editar o nome grava no banco e atualiza o menu', (
      tester,
    ) async {
      await abrirPerfil(tester);
      final novoNome = '${original.nome} E2E';

      await tocar(tester, find.text('Editar Perfil'));
      await digitar(tester, 'Nome completo', novoNome);
      await salvar(tester);
      expect(find.text(novoNome), findsWidgets);

      // Relê do banco: confirma que gravou de verdade (não só na tela).
      final relido = await injetor<RepositorioConsultora>().buscarMinha();
      expect(relido, isA<Sucesso<Consultora?>>());
      expect(injetor<RepositorioConsultora>().atual?.nome, novoNome);

      await tocar(tester, find.byTooltip('Voltar'));
      await abrirMenu(tester);
      expect(find.text(novoNome), findsWidgets);
    });

    testWidgets(
      'chave Pix: CPF inválido é recusado; e-mail é salvo e copiado',
      (tester) async {
        await abrirPerfil(tester);

        await tocar(tester, find.text('Editar Perfil'));
        await tocar(tester, campo('Tipo de chave Pix'));
        await tocar(tester, find.text('CPF'));
        await digitar(tester, 'Chave Pix', '111.111.111-11');
        await tocar(tester, find.text('Salvar Alterações'));
        expect(find.text('CPF inválido'), findsOneWidget);

        await tocar(tester, campo('Tipo de chave Pix'));
        await tocar(tester, find.text('E-mail'));
        await digitar(tester, 'Chave Pix', 'e2e@souconsultora.app');
        await salvar(tester);
        expect(find.text('Tipo: E-mail'), findsOneWidget);
        expect(find.text('e2e@souconsultora.app'), findsOneWidget);

        await tocar(tester, find.byTooltip('Copiar chave Pix'));
        expect(find.text('Chave Pix copiada'), findsOneWidget);
      },
    );

    testWidgets('cancelar a edição não grava', (tester) async {
      await abrirPerfil(tester);
      await tocar(tester, find.text('Editar Perfil'));
      await digitar(tester, 'Nome completo', 'Nome que não deve ficar');
      await tocar(tester, find.text('Cancelar'));

      expect(find.text('Meu Perfil'), findsOneWidget);
      expect(find.text('Nome que não deve ficar'), findsNothing);
    });

    testWidgets(
      'folha da foto oferece câmera e galeria (o fluxo nativo é manual)',
      (tester) async {
        await abrirPerfil(tester);
        await tocar(tester, find.byTooltip('Alterar foto'));
        expect(find.text('Foto do Perfil'), findsOneWidget);
        expect(find.text('Tirar foto'), findsOneWidget);
        expect(find.text('Escolher da galeria'), findsOneWidget);
        await tocar(tester, find.byTooltip('Fechar'));
      },
    );

    testWidgets(
      'sair pede confirmação (o teste cancela para manter a sessão)',
      (tester) async {
        await abrirPerfil(tester);
        await tocar(tester, find.text('Mais opções'));
        await tocar(tester, find.text('Sair da Conta'));
        expect(find.text('Sair da conta?'), findsOneWidget);

        await tocar(tester, find.text('Cancelar'));
        expect(find.text('Meu Perfil'), findsOneWidget);
      },
    );
  }, skip: pularGrupo('E2E-03'));

  // ————————————————————————————————————————————————————————————————
  // E2E-04 · Clientes
  // Apagar cliente não existe no app: o cenário reaproveita uma única
  // cliente "E2E Cliente" (cria só na primeira vez) e restaura o que editar.
  // ————————————————————————————————————————————————————————————————
  group('E2E-04 Clientes', () {
    const nomeE2e = 'E2E Cliente';

    // Só o card da lista: `find.text` também acharia o texto digitado na busca.
    final cardE2e = find.descendant(
      of: find.byType(CartaoListaApp),
      matching: find.text(nomeE2e),
    );

    Future<void> abrirClientes(WidgetTester tester) async {
      await abrirApp(tester);
      await tester.tap(find.bySemanticsLabel('Clientes').last);
      await tester.pumpAndSettle();
      // Lista com clientes mostra o contador; conta sem clientes mostra o estado vazio.
      final listaOuVazia = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'Nenhuma cliente ainda' ||
                (w.data ?? '').contains('cadastrad')),
      );
      await esperarAte(
        tester,
        listaOuVazia,
        descricao: 'lista de clientes (ou vazia)',
      );
    }

    /// Cadastra a cliente E2E (com CEP real) se ainda não existir.
    Future<void> garantirClienteE2e(WidgetTester tester) async {
      final vazia = find.text('Nenhuma cliente ainda').evaluate().isNotEmpty;
      if (!vazia) {
        await digitar(tester, 'Buscar cliente', nomeE2e);
        if (cardE2e.evaluate().isNotEmpty) return;
      }

      await tocar(
        tester,
        find.text(vazia ? 'Cadastrar cliente' : 'Novo cliente'),
      );
      await digitar(tester, 'Nome completo da cliente', nomeE2e);
      await digitar(tester, 'WhatsApp com DDD', '11999990001');
      await tocar(tester, find.text('Continuar'));
      await digitar(tester, 'CEP', '01001000');
      await esperarAte(
        tester,
        find.text('Praça da Sé'),
        descricao: 'endereço pelo ViaCEP',
      );
      await digitar(tester, 'Número', '10');
      await tocar(tester, find.text('Salvar Cliente'));
      await esperarAte(tester, cardE2e, descricao: 'cliente nova na lista');
    }

    testWidgets(
      'cadastra (1ª vez), busca sem diferenciar maiúsculas e abre detalhes e dados por cima',
      (tester) async {
        await abrirClientes(tester);
        await garantirClienteE2e(tester);

        await digitar(tester, 'Buscar cliente', 'e2e cliente');
        expect(cardE2e, findsOneWidget);

        await tocar(tester, cardE2e);
        await esperarAte(tester, find.text('Dados Cadastrais'));
        expect(
          find.bySemanticsLabel('Início'),
          findsNothing,
          reason: 'detalhe abre sem a barra',
        );

        await tocar(tester, find.text('Dados Cadastrais'));
        await esperarAte(tester, find.text('(11) 99999-0001'));
        await mostrar(tester, find.text('Praça da Sé, 10'));
        expect(find.text('Praça da Sé, 10'), findsOneWidget);
      },
    );

    testWidgets('editar as observações grava no banco e restaura no fim', (
      tester,
    ) async {
      await abrirClientes(tester);
      await garantirClienteE2e(tester);
      final repositorio = injetor<RepositorioClientes>();
      final id = repositorio.lista!.firstWhere((c) => c.nome == nomeE2e).id;
      final original =
          (await repositorio.buscarCliente(id) as Sucesso<Cliente?>).valor!;
      addTearDown(
        () => repositorio.salvar(
          id: id,
          nome: original.nome,
          whatsapp: original.whatsapp,
          dataNascimento: original.dataNascimento,
          observacoes: original.observacoes,
          endereco: original.endereco,
        ),
      );

      final nota =
          'Prefere florais E2E ${DateTime.now().millisecondsSinceEpoch}';
      await tocar(tester, cardE2e);
      await esperarAte(tester, find.text('Dados Cadastrais'));
      await tocar(tester, find.text('Dados Cadastrais'));
      await esperarAte(tester, find.text('Editar'));
      await tocar(tester, find.text('Editar'));
      await esperarAte(tester, find.text('Editar Cliente'));
      await digitar(tester, 'Observações ou preferências', nota);
      await tocar(tester, find.text('Continuar'));
      await tocar(tester, find.text('Salvar Cliente'));
      await esperarAte(tester, find.text('Dados Cadastrais'));
      await mostrar(tester, find.text(nota));
      expect(find.text(nota), findsOneWidget);

      // Relê do banco: confirma que gravou de verdade.
      final relido =
          (await repositorio.buscarCliente(id) as Sucesso<Cliente?>).valor!;
      expect(relido.observacoes, nota);
    });
  }, skip: pularGrupo('E2E-04'));

  // ————————————————————————————————————————————————————————————————
  // E2E-05 · Fornecedores
  // Não existe exclusão de fornecedor: o cenário reaproveita um único
  // fornecedor "E2E Fornecedor" (cria só na primeira vez) e sempre o
  // devolve a ativo no fim.
  // ————————————————————————————————————————————————————————————————
  group('E2E-05 Fornecedores', () {
    const nomeE2e = 'E2E Fornecedor';

    final cardE2e = find.descendant(
      of: find.byType(CartaoListaApp),
      matching: find.text(nomeE2e),
    );

    Future<void> abrirFornecedores(WidgetTester tester) async {
      await abrirApp(tester);
      await abrirMenu(tester);
      await tocarNoMenu(tester, 'Fornecedores & Marcas');
      final listaOuVazia = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'Nenhum fornecedor ainda' ||
                RegExp(r'^\d+ fornecedor').hasMatch(w.data ?? '')),
      );
      await esperarAte(
        tester,
        listaOuVazia,
        descricao: 'lista de fornecedores (ou vazia)',
      );
    }

    Future<void> buscar(WidgetTester tester, String texto) async {
      await tester.enterText(find.byType(TextField).first, texto);
      await tester.pumpAndSettle();
    }

    /// O fornecedor E2E pode ter sido criado por outro grupo (E2E-06):
    /// garante o telefone e o ramo que estes cenários conferem.
    Future<void> completarFornecedorE2e(WidgetTester tester) async {
      final repositorio = injetor<RepositorioFornecedores>();
      final atual = repositorio.lista!.firstWhere((f) => f.nome == nomeE2e);
      if (atual.telefone == fornecedorE2e.telefone) return;
      await repositorio.salvar(fornecedorE2e, id: atual.id);
      await tester.pumpAndSettle();
    }

    /// Cadastra o fornecedor E2E se ainda não existir.
    Future<void> garantirFornecedorE2e(WidgetTester tester) async {
      final vazia = find.text('Nenhum fornecedor ainda').evaluate().isNotEmpty;
      if (!vazia) {
        await buscar(tester, nomeE2e);
        if (cardE2e.evaluate().isNotEmpty) {
          await completarFornecedorE2e(tester);
          return;
        }
      }

      await tocar(
        tester,
        find.text(vazia ? 'Cadastrar fornecedor' : 'Fornecedor'),
      );
      await digitar(tester, 'Nome da marca', nomeE2e);
      await digitar(tester, 'Ramo', 'Teste automatizado');
      await digitar(tester, 'Telefone', '11999990002');
      await tocar(tester, find.text('Salvar'));
      await esperarAte(tester, cardE2e, descricao: 'fornecedor novo na lista');
    }

    testWidgets(
      'cadastra (1ª vez), busca sem diferenciar maiúsculas e abre os detalhes por cima',
      (tester) async {
        await abrirFornecedores(tester);
        await garantirFornecedorE2e(tester);

        await buscar(tester, 'e2e fornecedor');
        expect(cardE2e, findsOneWidget);

        await tocar(tester, cardE2e);
        await esperarAte(tester, find.text('Detalhes do Fornecedor'));
        expect(
          find.bySemanticsLabel('Início'),
          findsNothing,
          reason: 'detalhe abre sem a barra',
        );
        await mostrar(tester, find.text('(11) 99999-0002'));
        expect(find.text('(11) 99999-0002'), findsOneWidget);
        expect(find.textContaining('Excluir'), findsNothing);
      },
    );

    testWidgets('colocar em espera grava no banco e volta a ativo no fim', (
      tester,
    ) async {
      await abrirFornecedores(tester);
      await garantirFornecedorE2e(tester);
      final repositorio = injetor<RepositorioFornecedores>();
      final original = repositorio.lista!.firstWhere((f) => f.nome == nomeE2e);
      addTearDown(
        () => repositorio.salvar(
          Fornecedor(
            nome: original.nome,
            ramo: original.ramo,
            contato: original.contato,
            telefone: original.telefone,
            observacoes: original.observacoes,
          ),
          id: original.id,
        ),
      );

      await tocar(tester, cardE2e);
      await esperarAte(tester, find.text('Editar Fornecedor'));
      await tocar(tester, find.text('Editar Fornecedor'));
      await esperarAte(tester, find.text('Salvar'));
      await mostrar(tester, find.text('Em espera'));
      await tocar(tester, find.text('Em espera'));
      await tocar(tester, find.text('Salvar'));
      await esperarAte(tester, find.text('Detalhes do Fornecedor'));
      expect(find.text('Em espera'), findsOneWidget);

      // Relê do banco: confirma que gravou de verdade.
      final relido = await repositorio.buscarResumo(original.id);
      expect((relido as Sucesso).valor!.emEspera, isTrue);
    });
  }, skip: pularGrupo('E2E-05'));

  // ————————————————————————————————————————————————————————————————
  // E2E-06 · Produtos
  // ————————————————————————————————————————————————————————————————
  group('E2E-06 Produtos', () {
    const nomeE2e = 'E2E Produto';
    const marcaE2e = 'E2E Fornecedor';

    final cardE2e = find.descendant(
      of: find.byType(CartaoListaApp),
      matching: find.text(nomeE2e),
    );

    Future<void> abrirProdutos(WidgetTester tester) async {
      await abrirApp(tester);
      await tester.tap(find.bySemanticsLabel('Produtos').last);
      await tester.pumpAndSettle();
      final listaOuVazia = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'Nenhum produto ainda' ||
                RegExp(r'^\d+ produtos? cadastrados?').hasMatch(w.data ?? '')),
      );
      await esperarAte(
        tester,
        listaOuVazia,
        descricao: 'lista de produtos (ou vazia)',
      );
    }

    Future<void> buscar(WidgetTester tester, String texto) async {
      await tester.enterText(find.byType(TextField).first, texto);
      await tester.pumpAndSettle();
    }

    /// A marca E2E é criada pelo E2E-05; se ainda não existir, grava direto.
    Future<void> garantirMarcaE2e() async {
      final fornecedores = injetor<RepositorioFornecedores>();
      final lista = await fornecedores.carregar();
      final existe = (lista as Sucesso).valor.any((f) => f.nome == marcaE2e);
      if (!existe) await fornecedores.salvar(fornecedorE2e);
    }

    Future<void> escolher(
      WidgetTester tester,
      String campo,
      String opcao,
    ) async {
      await tocar(tester, find.text(campo));
      await tocar(tester, find.text(opcao).last);
    }

    /// Cadastra o produto E2E (sem foto) se ainda não existir.
    Future<void> garantirProdutoE2e(WidgetTester tester) async {
      final vazia = find.text('Nenhum produto ainda').evaluate().isNotEmpty;
      if (!vazia) {
        await buscar(tester, nomeE2e);
        if (cardE2e.evaluate().isNotEmpty) return;
      }

      await tocar(
        tester,
        find.text(vazia ? 'Cadastrar produto' : 'Novo produto'),
      );
      await esperarAte(tester, find.text('Continuar'));
      await digitar(tester, 'Nome do produto', nomeE2e);
      await escolher(tester, 'Escolha a marca', marcaE2e);
      await escolher(tester, 'Escolha a categoria', 'Perfumaria');
      await digitar(tester, 'Código', 'E2E-001');
      await tocar(tester, find.text('Continuar'));
      await esperarAte(tester, find.text('Salvar Produto'));
      await digitar(tester, 'Preço de venda', '9990');
      await tocar(tester, find.text('Salvar Produto'));
      await esperarAte(tester, cardE2e, descricao: 'produto novo na lista');
    }

    testWidgets(
      'cadastra (1ª vez) em 2 passos, aparece Esgotado, busca pelo código e abre os detalhes',
      (tester) async {
        await abrirProdutos(tester);
        await garantirMarcaE2e();
        await garantirProdutoE2e(tester);

        await buscar(tester, 'e2e-001');
        expect(cardE2e, findsOneWidget);
        expect(find.text('Esgotado'), findsWidgets);

        await tocar(tester, cardE2e);
        await esperarAte(tester, find.text('Detalhes do Produto'));
        expect(
          find.bySemanticsLabel('Início'),
          findsNothing,
          reason: 'detalhe abre sem a barra',
        );
        expect(find.text(marcaE2e.toUpperCase()), findsOneWidget);
        expect(find.textContaining('Excluir'), findsNothing);
      },
    );

    testWidgets('editar o preço grava no banco e volta ao original no fim', (
      tester,
    ) async {
      await abrirProdutos(tester);
      await garantirMarcaE2e();
      await garantirProdutoE2e(tester);
      final repositorio = injetor<RepositorioProdutos>();
      final original = repositorio.lista!.firstWhere((p) => p.nome == nomeE2e);
      addTearDown(
        () => repositorio.salvar(original.paraProduto(), id: original.id),
      );

      await buscar(tester, nomeE2e);
      await tocar(tester, cardE2e);
      await esperarAte(tester, find.text('Editar Produto'));
      await tocar(tester, find.text('Editar Produto'));
      await esperarAte(tester, find.text('Continuar'));
      await tocar(tester, find.text('Continuar'));
      await esperarAte(tester, find.text('Salvar Produto'));
      final novoPreco = original.precoVenda + 1000;
      await digitar(
        tester,
        'Preço de venda',
        FormatadorMoeda.formatarSemSimbolo(novoPreco),
      );
      await tocar(tester, find.text('Salvar Produto'));
      await esperarAte(tester, find.text('Detalhes do Produto'));

      // Relê do banco: confirma que gravou de verdade.
      final relido = await repositorio.buscarResumo(original.id);
      expect((relido as Sucesso).valor!.precoVenda, novoPreco);
    });
  }, skip: pularGrupo('E2E-06'));

  // ————————————————————————————————————————————————————————————————
  // E2E-07 · Estoque
  // ————————————————————————————————————————————————————————————————
  group('E2E-07 Estoque', () {
    const nomeProduto = 'E2E Produto';

    final cardProduto = find.descendant(
      of: find.byType(CartaoListaApp),
      matching: find.text(nomeProduto),
    );

    testWidgets(
      'lança 2 unidades pela aba Estoque, grava o lote no banco e apaga no fim',
      (tester) async {
        await abrirApp(tester);
        await tester.tap(find.bySemanticsLabel('Produtos').last);
        await tester.pumpAndSettle();
        await esperarAte(
          tester,
          find.textContaining('cadastrado'),
          descricao: 'lista de produtos',
        );
        await tester.enterText(find.byType(TextField).first, nomeProduto);
        await tester.pumpAndSettle();
        if (cardProduto.evaluate().isEmpty) {
          fail('Rode antes o E2E-06: ele cria o produto "$nomeProduto".');
        }

        final produtos = injetor<RepositorioProdutos>();
        final estoque = injetor<RepositorioEstoque>();
        final produto = produtos.lista!.firstWhere(
          (p) => p.nome == nomeProduto,
        );
        final antes = produto.qtdDisponivel;
        final lotesAntes = await estoque.lotes(produto.id);
        final idsAntes = {
          for (final lote in (lotesAntes as Sucesso).valor) lote.id,
        };
        // Apaga só o lote criado por este cenário (o saldo volta ao original).
        addTearDown(() async {
          final depois = await estoque.lotes(produto.id);
          for (final lote in (depois as Sucesso).valor) {
            if (!idsAntes.contains(lote.id)) await estoque.apagarLote(lote.id);
          }
        });

        await tocar(tester, cardProduto);
        await esperarAte(tester, find.text('Detalhes do Produto'));
        await tocar(tester, find.text('Estoque $antes'));
        await tocar(tester, find.text('Lançar Estoque'));
        await esperarAte(tester, find.text('Adicionar Produto ao Estoque'));

        await tocar(tester, find.byTooltip('Aumentar'));
        await tester.enterText(
          find.descendant(
            of: find.byType(CampoMoedaApp),
            matching: find.byType(EditableText),
          ),
          '5000',
        );
        await tester.pumpAndSettle();
        await mostrar(tester, find.text('Adicionar à Compra'));
        await tocar(tester, find.text('Adicionar à Compra'));
        await esperarAte(tester, find.text('1 item'));
        await tocar(tester, find.text('Salvar lançamento'));
        await esperarAte(tester, find.text('Detalhes do Produto'));
        await esperarAte(tester, find.text('Pronta entrega'));

        // Relê do banco: confirma que o lote foi gravado de verdade.
        final relidos = await estoque.lotes(produto.id);
        final novos = [
          for (final lote in (relidos as Sucesso).valor)
            if (!idsAntes.contains(lote.id)) lote,
        ];
        expect(novos.single.quantidade, 2);
        expect(novos.single.custoUnitario, 5000);
        expect(novos.single.fornecedorNome, fornecedorE2e.nome);
        expect(produtos.resumoEmCache(produto.id)!.qtdDisponivel, antes + 2);
      },
    );
  }, skip: pularGrupo('E2E-07'));
}
