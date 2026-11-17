// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/model/item_lancamento.dart';
import 'package:sou_consultora/core/repository/repositorio_categorias.dart';
import 'package:sou_consultora/core/repository/repositorio_estoque.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/produtos/detalhes/produtos_detalhes_screen.dart';
import 'package:sou_consultora/ui/modules/produtos/lancar_estoque/lancar_estoque_cubit.dart';
import 'package:sou_consultora/ui/modules/produtos/lancar_estoque/lancar_estoque_screen.dart';
import 'package:sou_consultora/ui/modules/produtos/lista/produtos_lista_screen.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';

import '../../auxiliares/falsos_estoque.dart';
import '../../auxiliares/falsos_fornecedores.dart';
import '../../auxiliares/falsos_produtos.dart';
import '../../auxiliares/montar_app.dart';

/// Abre [caminho] com uma rota "anterior" para o pop funcionar.
Future<void> _abrir(
  WidgetTester tester,
  String caminho, {
  required ServicoProdutosFalso produtos,
  required ServicoEstoqueFalso estoque,
}) async {
  usarTelaDeCelular(tester);
  final repositorioProdutos = repositorioProdutosDeTeste(produtos);
  injetor
    ..registerSingleton<RepositorioProdutos>(repositorioProdutos)
    ..registerSingleton<RepositorioEstoque>(
      repositorioEstoqueDeTeste(estoque, repositorioProdutos),
    )
    ..registerSingleton<RepositorioFornecedores>(
      repositorioFornecedoresDeTeste(ServicoFornecedoresFalso()),
    )
    ..registerSingleton<RepositorioCategorias>(repositorioCategoriasDeTeste());
  final roteador = GoRouter(
    initialLocation: '/inicio',
    routes: [
      GoRoute(
        path: '/inicio',
        builder: (_, _) => const Scaffold(body: Text('anterior')),
      ),
      GoRoute(
        path: '/produtos',
        builder: (_, _) => const Scaffold(body: ProdutosListaScreen()),
      ),
      GoRoute(
        path: '/produtos/lancar-estoque',
        builder: (_, e) => LancarEstoqueScreen(
          produtoInicialId: e.uri.queryParameters['produto'],
        ),
      ),
      GoRoute(
        path: '/produtos/:id',
        builder: (_, e) =>
            ProdutosDetalhesScreen(idProduto: e.pathParameters['id']!),
      ),
    ],
  );
  addTearDown(() async {
    roteador.dispose();
    await injetor.reset();
  });
  await tester.pumpWidget(appDeTeste(roteador: roteador));
  await tester.pumpAndSettle();
  roteador.push(caminho);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('Lançar estoque (cubit)', () {
    late ServicoProdutosFalso produtos;
    late ServicoEstoqueFalso estoque;
    late LancarEstoqueCubit cubit;

    setUp(() async {
      produtos = ServicoProdutosFalso(
        resumos: [produtoDto('p1', 'Kit Lily'), produtoDto('p2', 'Batom')],
      );
      estoque = ServicoEstoqueFalso(produtos: produtos);
      final repositorioProdutos = repositorioProdutosDeTeste(produtos);
      cubit = LancarEstoqueCubit(
        produtos: repositorioProdutos,
        estoque: repositorioEstoqueDeTeste(estoque, repositorioProdutos),
        agora: () => DateTime(2026, 11, 17, 10),
      );
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() => cubit.close());

    ItemLancamento item(int indice, {int quantidade = 1, int custo = 1000}) =>
        ItemLancamento(
          produto: cubit.state.produtos[indice],
          quantidade: quantidade,
          custoUnitario: custo,
        );

    test('começa com hoje, sem itens e sem poder salvar', () {
      expect(cubit.state.dataCompra, DateTime(2026, 11, 17));
      expect(cubit.state.produtos.length, 2);
      expect(cubit.state.podeSalvar, isFalse);
    });

    test('adiciona, recusa repetido, troca e remove; totais', () {
      cubit
        ..adicionarItem(item(0, quantidade: 3, custo: 15500))
        ..adicionarItem(item(1, quantidade: 10, custo: 2850));
      expect(cubit.state.lancamento.totalUnidades, 13);
      expect(cubit.state.lancamento.custoTotal, 75000);

      cubit.adicionarItem(item(0));
      expect(cubit.state.itens.length, 2);
      expect(cubit.state.aviso, LancamentoEstoque.mensagemRepetido);
      expect(cubit.jaNaCompra('p1'), isTrue);
      expect(cubit.jaNaCompra('p1', indiceEditado: 0), isFalse);

      cubit.substituirItem(1, item(1, quantidade: 2, custo: 2850));
      expect(cubit.state.lancamento.totalUnidades, 5);

      cubit.removerItem(0);
      expect(cubit.state.itens.single.produto.nome, 'Batom');
    });

    test('data futura bloqueia o salvar', () {
      cubit
        ..adicionarItem(item(0))
        ..alterarData(DateTime(2026, 11, 18));
      expect(cubit.state.erroData, isNotNull);
      expect(cubit.state.podeSalvar, isFalse);
    });

    test('salvar envia os itens; falha mantém tudo na tela', () async {
      cubit.adicionarItem(item(0, quantidade: 3, custo: 15500));
      estoque.falharRede = true;
      await cubit.salvar();
      expect(cubit.state.aviso, isNotNull);
      expect(cubit.state.itens.length, 1);
      expect(cubit.state.salvo, isFalse);

      estoque.falharRede = false;
      await cubit.salvar();
      expect(cubit.state.salvo, isTrue);
      expect(estoque.lancados.single.itens.single.quantidade, 3);
    });
  });

  group('Lançar estoque (tela)', () {
    testWidgets(
      'vindo do produto: folha abre com ele, mostra a margem e salva',
      (tester) async {
        final produtos = ServicoProdutosFalso(
          resumos: [produtoDto('p1', 'Kit Lily', precoVenda: 21990)],
        );
        final estoque = ServicoEstoqueFalso(produtos: produtos);
        await _abrir(
          tester,
          '/produtos/lancar-estoque?produto=p1',
          produtos: produtos,
          estoque: estoque,
        );

        expect(find.text('Adicionar Produto ao Estoque'), findsOneWidget);
        expect(find.text('Kit Lily'), findsWidgets);

        final custo = find.descendant(
          of: find.byType(CampoMoedaApp),
          matching: find.byType(EditableText),
        );
        await tester.enterText(custo.first, '15500');
        await tester.pumpAndSettle();
        expect(find.text('Excelente'), findsOneWidget);

        await tester.ensureVisible(find.text('Adicionar à Compra'));
        await tester.tap(find.text('Adicionar à Compra'));
        await tester.pumpAndSettle();
        expect(find.text('1 item'), findsOneWidget);
        expect(find.text(FormatadorMoeda.formatar(15500)), findsOneWidget);

        await tester.tap(find.text('Salvar lançamento'));
        await tester.pumpAndSettle();
        expect(find.text('anterior'), findsOneWidget);
        expect(estoque.lancados.single.custoTotal, 15500);
      },
    );

    testWidgets('cancelar com itens pede confirmação', (tester) async {
      final produtos = ServicoProdutosFalso(
        resumos: [produtoDto('p1', 'Kit Lily')],
      );
      await _abrir(
        tester,
        '/produtos/lancar-estoque?produto=p1',
        produtos: produtos,
        estoque: ServicoEstoqueFalso(produtos: produtos),
      );
      final custo = find.descendant(
        of: find.byType(CampoMoedaApp),
        matching: find.byType(EditableText),
      );
      await tester.enterText(custo.first, '1000');
      await tester.ensureVisible(find.text('Adicionar à Compra'));
      await tester.tap(find.text('Adicionar à Compra'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Descartar lançamento?'), findsOneWidget);
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      expect(find.text('anterior'), findsOneWidget);
    });
  });

  group('Aba Estoque', () {
    testWidgets('resumo, lotes, saídas vazias e apagar lote sem vendas', (
      tester,
    ) async {
      final produtos = ServicoProdutosFalso(
        resumos: [produtoDto('p1', 'Kit Lily', qtdDisponivel: 4)],
      );
      final estoque = ServicoEstoqueFalso(
        produtos: produtos,
        lotes: [
          loteDto(
            'l1',
            'p1',
            quantidade: 2,
            disponivel: 1,
            custo: 12480,
            saidas: 1,
          ),
          loteDto('l2', 'p1', numero: 2, custo: 15500),
        ],
      );
      await _abrir(
        tester,
        '/produtos/p1',
        produtos: produtos,
        estoque: estoque,
      );

      await tester.tap(find.text('Estoque 4'));
      await tester.pumpAndSettle();
      expect(find.text('4 unidades'), findsOneWidget);
      expect(find.text('Pronta entrega'), findsOneWidget);
      expect(find.text(FormatadorMoeda.formatar(14745)), findsOneWidget);
      expect(find.text(FormatadorMoeda.formatar(58980)), findsOneWidget);
      expect(find.text('Lançar Estoque'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('#01'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('1 un restante'), findsOneWidget);
      expect(find.byTooltip('Apagar lote #01'), findsNothing);
      expect(find.byTooltip('Apagar lote #02'), findsOneWidget);

      await tester.tap(find.byTooltip('Apagar lote #02'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar lote'));
      await tester.pumpAndSettle();
      expect(estoque.apagados, ['l2']);
      expect(find.text('#02'), findsNothing);
      expect(find.text('1 unidade'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Saídas'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Saídas'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma venda ainda'), findsOneWidget);
    });
  });

  group('Lista', () {
    testWidgets('atalho Lançar estoque abre o lançamento vazio', (
      tester,
    ) async {
      final produtos = ServicoProdutosFalso(
        resumos: [produtoDto('p1', 'Kit Lily')],
      );
      await _abrir(
        tester,
        '/produtos',
        produtos: produtos,
        estoque: ServicoEstoqueFalso(produtos: produtos),
      );

      await tester.tap(find.text('Lançar estoque'));
      await tester.pumpAndSettle();
      expect(find.text('Lançar Estoque'), findsOneWidget);
      expect(find.text('0 itens'), findsOneWidget);
      expect(find.text('Adicionar Produto ao Estoque'), findsNothing);
    });
  });
}
