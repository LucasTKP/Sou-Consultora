// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/model/categoria.dart';
import 'package:sou_consultora/core/model/filtro_produtos.dart';
import 'package:sou_consultora/core/model/origem_foto.dart';
import 'package:sou_consultora/core/repository/repositorio_catalogo.dart';
import 'package:sou_consultora/core/repository/repositorio_categorias.dart';
import 'package:sou_consultora/core/repository/repositorio_estoque.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/produtos/detalhes/produtos_detalhes_screen.dart';
import 'package:sou_consultora/ui/modules/produtos/formulario/produtos_formulario_cubit.dart';
import 'package:sou_consultora/ui/modules/produtos/formulario/produtos_formulario_screen.dart';
import 'package:sou_consultora/ui/modules/produtos/importar/produtos_importar_screen.dart';
import 'package:sou_consultora/ui/modules/produtos/lista/produtos_lista_cubit.dart';
import 'package:sou_consultora/ui/modules/produtos/lista/produtos_lista_screen.dart';
import 'package:sou_consultora/ui/modules/produtos/lista/produtos_lista_state.dart';

import '../../auxiliares/falsos_catalogo.dart';
import '../../auxiliares/falsos_consultora.dart';
import '../../auxiliares/falsos_estoque.dart';
import '../../auxiliares/falsos_fornecedores.dart';
import '../../auxiliares/falsos_produtos.dart';
import '../../auxiliares/montar_app.dart';

/// Abre [caminho] com uma rota "anterior" para o pop funcionar.
Future<void> _abrir(
  WidgetTester tester,
  ServicoProdutosFalso servico,
  String caminho, {
  ServicoFornecedoresFalso? fornecedores,
  ServicoCatalogoFalso? catalogo,
}) async {
  usarTelaDeCelular(tester);
  final produtos = repositorioProdutosDeTeste(servico);
  injetor
    ..registerSingleton<RepositorioProdutos>(produtos)
    ..registerSingleton<RepositorioEstoque>(
      repositorioEstoqueDeTeste(ServicoEstoqueFalso(), produtos),
    )
    ..registerSingleton<RepositorioFornecedores>(
      repositorioFornecedoresDeTeste(
        fornecedores ??
            ServicoFornecedoresFalso(resumos: [fornecedorDto('m1', 'Natura')]),
      ),
    )
    ..registerSingleton<RepositorioCategorias>(repositorioCategoriasDeTeste())
    ..registerSingleton<RepositorioCatalogo>(
      repositorioCatalogoDeTeste(catalogo),
    );
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
        path: '/produtos/novo',
        builder: (_, _) => const ProdutosFormularioScreen(),
      ),
      GoRoute(
        path: '/fornecedores/novo',
        builder: (_, _) =>
            const Scaffold(body: Text('tela de novo fornecedor')),
      ),
      GoRoute(
        path: '/produtos/importar',
        builder: (_, _) => const ProdutosImportarScreen(),
      ),
      GoRoute(
        path: '/produtos/:id',
        builder: (_, e) =>
            ProdutosDetalhesScreen(idProduto: e.pathParameters['id']!),
      ),
      GoRoute(
        path: '/produtos/:id/editar',
        builder: (_, e) =>
            ProdutosFormularioScreen(idProduto: e.pathParameters['id']),
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

ProdutosFormularioCubit _formulario(
  ServicoProdutosFalso servico, {
  String? idProduto,
  ServicoFornecedoresFalso? fornecedores,
  FotoDispositivoFalsa? fotos,
  ServicoCatalogoFalso? catalogo,
}) {
  return ProdutosFormularioCubit(
    idProduto: idProduto,
    produtos: repositorioProdutosDeTeste(servico, fotos: fotos),
    fornecedores: repositorioFornecedoresDeTeste(
      fornecedores ??
          ServicoFornecedoresFalso(
            resumos: [
              fornecedorDto('m1', 'Natura'),
              fornecedorDto('m2', 'Avon', ativo: false),
            ],
          ),
    ),
    categorias: repositorioCategoriasDeTeste(),
    catalogo: repositorioCatalogoDeTeste(catalogo),
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('Lista (cubit)', () {
    test('filtra, busca, ordena e acompanha o repositório', () async {
      final servico = ServicoProdutosFalso(
        resumos: [
          produtoDto('p1', 'Batom', precoVenda: 4999, qtdDisponivel: 8),
          produtoDto('p2', 'Kit Lily', precoVenda: 24000, qtdDisponivel: 1),
          produtoDto('p3', 'Malbec', precoVenda: 19990),
        ],
      );
      final repositorio = repositorioProdutosDeTeste(servico);
      final cubit = ProdutosListaCubit(repositorio: repositorio);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.carregamento, CarregamentoProdutos.pronto);
      expect(cubit.state.visiveis.map((p) => p.nome), [
        'Kit Lily',
        'Malbec',
        'Batom',
      ]);

      cubit.inverterOrdem();
      expect(cubit.state.visiveis.first.nome, 'Batom');

      cubit.alterarEstoque(StatusFiltroEstoque.esgotado);
      expect(cubit.state.visiveis.map((p) => p.nome), ['Malbec']);

      cubit
        ..alterarEstoque(StatusFiltroEstoque.todos)
        ..alterarBusca('lily');
      expect(cubit.state.visiveis.map((p) => p.nome), ['Kit Lily']);

      servico.resumos = [...servico.resumos, produtoDto('p4', 'Lily Lumière')];
      await repositorio.carregar();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.visiveis.length, 2);
      await cubit.close();
    });
  });

  group('Lista (tela)', () {
    testWidgets(
      'nome longo usa a largura toda; estoque fica na linha do valor',
      (tester) async {
        const nome =
            'Natura Ekos Sabonete em Barra Puro Vegetal Esfoliante Sortido Açaí '
            'Andiroba Maracujá e Castanha 4 Unidades de 100 g';
        final servico = ServicoProdutosFalso(
          resumos: [produtoDto('p1', nome, precoVenda: 24000)],
        );
        await _abrir(tester, servico, '/produtos');

        final tituloCaixa = tester.getRect(find.textContaining('Natura Ekos'));
        final valor = tester.getRect(find.text('R\$ 240,00'));
        final estoque = tester.getRect(find.text('Esgotado'));

        // O nome ocupa duas linhas e a largura toda do card (o estoque não o
        // aperta mais pela direita).
        expect(tituloCaixa.height, greaterThan(30));
        expect(tituloCaixa.width, greaterThan(200));
        // Valor e estoque ficam abaixo do nome, na linha de baixo.
        expect(valor.top, greaterThanOrEqualTo(tituloCaixa.bottom - 1));
        expect(estoque.top, greaterThanOrEqualTo(tituloCaixa.bottom - 1));
      },
    );

    testWidgets('lista vazia convida a cadastrar', (tester) async {
      await _abrir(tester, ServicoProdutosFalso(), '/produtos');

      expect(find.text('Nenhum produto ainda'), findsOneWidget);
      expect(find.text('Cadastrar produto'), findsOneWidget);
      expect(find.text('Adicionar'), findsNothing);
    });

    testWidgets('busca sem resultado mantém o campo', (tester) async {
      await _abrir(
        tester,
        ServicoProdutosFalso(resumos: [produtoDto('p1', 'Batom')]),
        '/produtos',
      );

      await tester.enterText(find.byType(EditableText).first, 'xyz');
      await tester.pumpAndSettle();
      expect(find.text('Nenhum produto encontrado'), findsOneWidget);
      expect(find.byType(EditableText), findsWidgets);
    });

    testWidgets('erro com tentar novamente', (tester) async {
      final servico = ServicoProdutosFalso(resumos: [produtoDto('p1', 'Batom')])
        ..falharRede = true;
      await _abrir(tester, servico, '/produtos');
      expect(find.text('Tentar novamente'), findsOneWidget);

      servico.falharRede = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Batom'), findsOneWidget);
    });
  });

  group('Formulário (cubit)', () {
    test('Continuar fica no passo 1 sem marca e categoria', () async {
      final cubit = _formulario(ServicoProdutosFalso());
      await Future<void>.delayed(Duration.zero);

      cubit
        ..alterarNome('Kit Lily')
        ..continuar();

      expect(cubit.state.passo, 1);
      expect(cubit.state.erroMarca, 'Escolha a marca');
      expect(cubit.state.erroCategoria, 'Escolha a categoria');
      await cubit.close();
    });

    test('só marcas ativas no seletor de um produto novo', () async {
      final cubit = _formulario(ServicoProdutosFalso());
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.marcasDisponiveis.map((m) => m.nome), ['Natura']);
      await cubit.close();
    });

    test('preço vazio não grava; voltar mantém os dados', () async {
      final servico = ServicoProdutosFalso();
      final cubit = _formulario(servico);
      await Future<void>.delayed(Duration.zero);

      cubit
        ..alterarNome('Kit Lily')
        ..alterarMarca(cubit.state.marcasDisponiveis.first)
        ..alterarCategoria(const Categoria(id: 'c1', nome: 'Perfumaria'))
        ..continuar();
      expect(cubit.state.passo, 2);

      await cubit.salvar();
      expect(cubit.state.erroPrecoVenda, 'Informe o preço de venda');
      expect(servico.salvos, isEmpty);

      cubit.voltar();
      expect(cubit.state.passo, 1);
      expect(cubit.state.nome, 'Kit Lily');
      expect(cubit.state.fornecedorId, 'm1');
      await cubit.close();
    });

    test('salva com foto, sem durabilidade e custo zero como nulo', () async {
      final servico = ServicoProdutosFalso();
      final fotos = FotoDispositivoFalsa();
      final cubit = _formulario(servico, fotos: fotos);
      await Future<void>.delayed(Duration.zero);

      await cubit.escolherFoto(OrigemFoto.galeria);
      cubit
        ..alterarNome('Kit Lily')
        ..alterarMarca(cubit.state.marcasDisponiveis.first)
        ..alterarCategoria(const Categoria(id: 'c1', nome: 'Perfumaria'))
        ..continuar()
        ..alterarPrecoCusto(0)
        ..alterarPrecoVenda(21990);
      await cubit.salvar();

      expect(fotos.ultimaOrigem, OrigemFoto.galeria);
      final salvo = servico.salvos.single.produto;
      expect(salvo.caminhoFoto, 'u1/produtos/1.jpg');
      expect(salvo.durabilidadeDias, isNull);
      expect(salvo.precoCustoCentavos, isNull);
      expect(cubit.state.salvo, isTrue);
      await cubit.close();
    });

    test('falha ao salvar mostra o aviso e mantém os dados', () async {
      final servico = ServicoProdutosFalso()..falharAoSalvar = true;
      final cubit = _formulario(servico);
      await Future<void>.delayed(Duration.zero);

      cubit
        ..alterarNome('Kit Lily')
        ..alterarMarca(cubit.state.marcasDisponiveis.first)
        ..alterarCategoria(const Categoria(id: 'c1', nome: 'Perfumaria'))
        ..continuar()
        ..alterarPrecoVenda(21990);
      await cubit.salvar();

      expect(cubit.state.aviso, isNotNull);
      expect(cubit.state.salvo, isFalse);
      expect(cubit.state.nome, 'Kit Lily');
      await cubit.close();
    });

    test('editar carrega o produto e mantém a marca em espera', () async {
      final servico = ServicoProdutosFalso(
        resumos: [
          produtoDto(
            'p1',
            'Batom',
            precoVenda: 4999,
            fornecedorId: 'm2',
            durabilidadeDias: 60,
          ),
        ],
      );
      final cubit = _formulario(servico, idProduto: 'p1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.nome, 'Batom');
      expect(cubit.state.marcasDisponiveis.map((m) => m.nome), [
        'Natura',
        'Avon',
      ]);
      expect(cubit.state.marcaEscolhida?.nome, 'Avon');

      cubit
        ..continuar()
        ..alterarPrecoVenda(5999);
      await cubit.salvar();
      expect(servico.salvos.single.id, 'p1');
      expect(servico.salvos.single.produto.precoVendaCentavos, 5999);
      expect(servico.salvos.single.produto.durabilidadeDias, 60);
      await cubit.close();
    });
  });

  group('Formulário (tela)', () {
    testWidgets('novo: importar do catálogo preenche o passo 1', (
      tester,
    ) async {
      final catalogo = ServicoCatalogoFalso(
        itens: [catalogoDto('174918', 'Balm labial ameixa')],
      );
      await _abrir(
        tester,
        ServicoProdutosFalso(),
        '/produtos/novo',
        catalogo: catalogo,
      );

      expect(find.text('Importar do catálogo'), findsOneWidget);
      expect(
        find.text('Adicionar foto'),
        findsOneWidget,
      );

      await tester.tap(find.text('Importar do catálogo'));
      await tester.pumpAndSettle();
      expect(find.text('Balm labial ameixa'), findsOneWidget);
      await tester.tap(find.text('Balm labial ameixa'));
      await tester.pumpAndSettle();

      expect(find.text('Novo Produto'), findsOneWidget);
      expect(find.text('Balm labial ameixa'), findsOneWidget);
      expect(find.text('174918'), findsOneWidget);
      expect(find.text('Natura'), findsOneWidget);
      expect(find.text('Maquiagem'), findsOneWidget);
      expect(find.text('Trocar foto'), findsOneWidget);
      expect(catalogo.fotosBaixadas, ['natura/174918.jpg']);
    });

    testWidgets('marca: o botão Cadastrar fornecedor fica na folha, sem seta', (
      tester,
    ) async {
      await _abrir(tester, ServicoProdutosFalso(), '/produtos/novo');

      // Nada de seta ao lado do campo: o atalho agora é um botão na folha.
      expect(find.byTooltip('Cadastrar fornecedor'), findsNothing);
      expect(find.text('Cadastrar fornecedor'), findsNothing);

      await tester.tap(find.text('Escolha a marca'));
      await tester.pumpAndSettle();
      expect(find.text('Cadastrar fornecedor'), findsOneWidget);

      await tester.tap(find.text('Cadastrar fornecedor'));
      await tester.pumpAndSettle();
      expect(find.text('tela de novo fornecedor'), findsOneWidget);
    });

    testWidgets('editar não mostra o botão de importar', (tester) async {
      final servico = ServicoProdutosFalso(
        resumos: [produtoDto('p1', 'Batom', precoVenda: 4999)],
      );
      await _abrir(tester, servico, '/produtos/p1/editar');
      expect(find.text('Importar do catálogo'), findsNothing);
    });

    testWidgets('novo: passo 1 → passo 2 → voltar; cancelar não grava', (
      tester,
    ) async {
      final servico = ServicoProdutosFalso();
      await _abrir(tester, servico, '/produtos/novo');

      expect(find.text('Novo Produto'), findsOneWidget);
      expect(find.text('Passo 1 de 2: Dados do Produto'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).first, 'Kit Lily');
      await tester.tap(find.text('Escolha a marca'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Natura').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escolha a categoria'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perfumaria').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Passo 2 de 2: Preços e Durabilidade'), findsOneWidget);
      expect(find.text('CONFIGURANDO PRODUTO'), findsOneWidget);
      expect(find.text('Natura • Perfumaria'), findsOneWidget);

      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Passo 1 de 2: Dados do Produto'), findsOneWidget);
      expect(find.text('Kit Lily'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('anterior'), findsOneWidget);
      expect(servico.salvos, isEmpty);
    });

    testWidgets('editar: título e campos preenchidos', (tester) async {
      final servico = ServicoProdutosFalso(
        resumos: [produtoDto('p1', 'Batom', codigo: 'NAT-1')],
      );
      await _abrir(tester, servico, '/produtos/p1/editar');

      expect(find.text('Editar Produto'), findsOneWidget);
      expect(find.text('Batom'), findsOneWidget);
      expect(find.text('NAT-1'), findsOneWidget);
      expect(find.text('Natura'), findsOneWidget);
    });
  });

  group('Detalhes', () {
    testWidgets('mostra topo e informações; sem excluir', (tester) async {
      final servico = ServicoProdutosFalso(
        resumos: [
          produtoDto(
            'p1',
            'Kit Lily',
            fornecedorNome: 'O Boticário',
            precoVenda: 21990,
            precoCusto: 14293,
            durabilidadeDias: 60,
            codigo: 'BOT-74892',
            observacoes: 'Fragrância floral',
            qtdDisponivel: 4,
            validadeAtual: DateTime(2026, 11, 30),
          ),
        ],
      );
      await _abrir(tester, servico, '/produtos/p1');

      expect(find.text('O BOTICÁRIO'), findsOneWidget);
      expect(find.text(FormatadorMoeda.formatar(14293)), findsOneWidget);
      expect(find.text('60 dias (2 meses)'), findsOneWidget);
      expect(find.text('Ideal para prever recompra'), findsOneWidget);
      expect(find.text('BOT-74892'), findsOneWidget);
      expect(find.text('30/11/2026'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Fragrância floral'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Fragrância floral'), findsOneWidget);
      expect(find.textContaining('Excluir'), findsNothing);
    });

    testWidgets('sem custo, código, durabilidade e lotes esconde as linhas', (
      tester,
    ) async {
      final servico = ServicoProdutosFalso(
        resumos: [produtoDto('p1', 'Batom')],
      );
      await _abrir(tester, servico, '/produtos/p1');

      expect(find.text('Preço de venda'), findsOneWidget);
      expect(find.text('Categoria'), findsOneWidget);
      expect(find.text('Preço de custo'), findsNothing);
      expect(find.text('Código / Ref.'), findsNothing);
      expect(find.text('Durabilidade estimada'), findsNothing);
      expect(find.text('Validade atual'), findsNothing);
    });

    testWidgets('editar e salvar volta e recarrega os detalhes', (
      tester,
    ) async {
      final servico = ServicoProdutosFalso(
        resumos: [produtoDto('p1', 'Batom', precoVenda: 4999)],
      );
      await _abrir(tester, servico, '/produtos/p1');

      await tester.tap(find.text('Editar Produto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(EditableText).at(1),
        FormatadorMoeda.formatarSemSimbolo(5999),
      );
      await tester.tap(find.text('Salvar Produto'));
      await tester.pumpAndSettle();

      expect(find.text('Detalhes do Produto'), findsOneWidget);
      expect(find.text(FormatadorMoeda.formatar(5999)), findsWidgets);
    });
  });
}
