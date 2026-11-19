import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/model/fornecedor.dart';
import 'package:sou_consultora/core/model/produto_catalogo.dart';
import 'package:sou_consultora/core/repository/repositorio_catalogo.dart';
import 'package:sou_consultora/ui/modules/produtos/formulario/produtos_formulario_cubit.dart';
import 'package:sou_consultora/ui/modules/produtos/importar/produtos_importar_cubit.dart';
import 'package:sou_consultora/ui/modules/produtos/importar/produtos_importar_screen.dart';

import '../../auxiliares/falsos_catalogo.dart';
import '../../auxiliares/falsos_fornecedores.dart';
import '../../auxiliares/falsos_produtos.dart';
import '../../auxiliares/montar_app.dart';

ServicoCatalogoFalso _catalogo() => ServicoCatalogoFalso(
  itens: [
    catalogoDto('1', 'Balm labial ameixa'),
    catalogoDto('2', 'Sabonete Ekos', categoria: 'Corpo e banho'),
    catalogoDto('3', 'Batom Avon', marca: 'Avon'),
  ],
);

ProdutosFormularioCubit _formulario({
  required ServicoCatalogoFalso catalogo,
  required ServicoFornecedoresFalso fornecedores,
}) => ProdutosFormularioCubit(
  produtos: repositorioProdutosDeTeste(ServicoProdutosFalso()),
  fornecedores: repositorioFornecedoresDeTeste(fornecedores),
  categorias: repositorioCategoriasDeTeste(),
  catalogo: repositorioCatalogoDeTeste(catalogo),
);

Future<void> _pronto() => Future<void>.delayed(Duration.zero);

void main() {
  group('Importar no cadastro (cubit)', () {
    test(
      'preenche nome, código, marca, categoria e foto; preço fica vazio',
      () async {
        final catalogo = _catalogo();
        final cubit = _formulario(
          catalogo: catalogo,
          fornecedores: ServicoFornecedoresFalso(
            resumos: [fornecedorDto('m1', 'Natura')],
          ),
        );
        await _pronto();
        await cubit.importar(
          const ProdutoCatalogo(
            id: 'id-1',
            marca: 'Natura',
            codigo: '1',
            nome: 'Balm labial ameixa',
            categoria: 'Maquiagem',
            caminhoFoto: 'natura/1.jpg',
          ),
        );

        final estado = cubit.state;
        expect(estado.nome, 'Balm labial ameixa');
        expect(estado.codigo, '1');
        expect(estado.fornecedorId, 'm1');
        expect(estado.categoriaId, 'c2'); // Maquiagem
        expect(estado.fotoNova, catalogo.bytesDaFoto);
        expect(estado.precoVenda, isNull);
        expect(estado.versaoPreenchimento, 1);
        await cubit.close();
      },
    );

    test(
      'marca que a consultora ainda não tem é criada como fornecedor',
      () async {
        final fornecedores = ServicoFornecedoresFalso();
        final cubit = _formulario(
          catalogo: _catalogo(),
          fornecedores: fornecedores,
        );
        await _pronto();

        await cubit.importar(
          const ProdutoCatalogo(
            id: 'x',
            marca: 'Eudora',
            codigo: '7',
            nome: 'Batom Eudora',
            categoria: 'Maquiagem',
          ),
        );

        expect(fornecedores.salvos.map((s) => s.fornecedor.nome), ['Eudora']);
        expect(fornecedores.salvos.single.fornecedor.ramo, isNotNull);
        expect(cubit.state.marcaEscolhida?.nome, 'Eudora');
        await cubit.close();
      },
    );

    test('marca em espera não é duplicada nem escolhida: avisa', () async {
      final fornecedores = ServicoFornecedoresFalso(
        resumos: [fornecedorDto('m2', 'Avon', ativo: false)],
      )..falhaAoSalvar = const FalhaValidacao(Fornecedor.mensagemDuplicado);
      final cubit = _formulario(
        catalogo: _catalogo(),
        fornecedores: fornecedores,
      );
      await _pronto();

      await cubit.importar(
        const ProdutoCatalogo(
          id: 'x',
          marca: 'Avon',
          codigo: '3',
          nome: 'Batom Avon',
        ),
      );

      expect(cubit.state.fornecedorId, isNull);
      expect(cubit.state.nome, 'Batom Avon');
      expect(cubit.state.aviso, isNotNull);
      await cubit.close();
    });

    test('categoria sem equivalente fica vazia', () async {
      final cubit = _formulario(
        catalogo: _catalogo(),
        fornecedores: ServicoFornecedoresFalso(
          resumos: [fornecedorDto('m1', 'Natura')],
        ),
      );
      await _pronto();
      await cubit.importar(
        const ProdutoCatalogo(
          id: 'x',
          marca: 'Natura',
          codigo: '5',
          nome: 'Algo',
          categoria: 'Categoria Inexistente',
        ),
      );
      expect(cubit.state.categoriaId, isNull);
      expect(cubit.state.fornecedorId, 'm1');
      await cubit.close();
    });

    test(
      'falha ao baixar a foto avisa, mas os campos ficam preenchidos',
      () async {
        final catalogo = _catalogo()..falharFoto = true;
        final cubit = _formulario(
          catalogo: catalogo,
          fornecedores: ServicoFornecedoresFalso(
            resumos: [fornecedorDto('m1', 'Natura')],
          ),
        );
        await _pronto();
        await cubit.importar(
          const ProdutoCatalogo(
            id: 'x',
            marca: 'Natura',
            codigo: '1',
            nome: 'Balm',
            categoria: 'Maquiagem',
            caminhoFoto: 'natura/1.jpg',
          ),
        );
        expect(cubit.state.nome, 'Balm');
        expect(cubit.state.fotoNova, isNull);
        expect(cubit.state.aviso, isNotNull);
        await cubit.close();
      },
    );
  });

  group('Tela de importar', () {
    Future<void> abrir(
      WidgetTester tester,
      ServicoCatalogoFalso catalogo,
    ) async {
      usarTelaDeCelular(tester);
      injetor.registerSingleton<RepositorioCatalogo>(
        repositorioCatalogoDeTeste(catalogo),
      );
      addTearDown(() => injetor.reset());
      final roteador = GoRouter(
        initialLocation: '/inicio',
        routes: [
          GoRoute(
            path: '/inicio',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push<ProdutoCatalogo>('/importar'),
                child: const Text('abrir'),
              ),
            ),
          ),
          GoRoute(
            path: '/importar',
            builder: (_, _) => const ProdutosImportarScreen(),
          ),
        ],
      );
      addTearDown(roteador.dispose);
      await tester.pumpWidget(appDeTeste(roteador: roteador));
      await tester.pumpAndSettle();
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('lista o catálogo, filtra por marca e busca por nome', (
      tester,
    ) async {
      final catalogo = _catalogo();
      await abrir(tester, catalogo);

      expect(find.text('Importar do catálogo'), findsOneWidget);
      expect(find.text('Balm labial ameixa'), findsOneWidget);
      expect(find.text('Batom Avon'), findsOneWidget);
      expect(find.text('Natura · Cód. 1'), findsOneWidget);

      await tester.tap(find.text('Avon').first);
      await tester.pumpAndSettle();
      expect(find.text('Batom Avon'), findsOneWidget);
      expect(find.text('Balm labial ameixa'), findsNothing);
      expect(catalogo.buscas.last.marca, 'Avon');

      await tester.tap(find.text('Todas'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, 'sabonete');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Sabonete Ekos'), findsOneWidget);
      expect(find.text('Balm labial ameixa'), findsNothing);
    });

    testWidgets('sem resultado mostra o estado vazio; falha mostra erro', (
      tester,
    ) async {
      final catalogo = _catalogo();
      await abrir(tester, catalogo);

      await tester.enterText(find.byType(EditableText).first, 'zzzz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum produto encontrado'), findsOneWidget);

      catalogo.falharListar = true;
      await tester.enterText(find.byType(EditableText).first, 'balm');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Sem conexão.'), findsOneWidget);
    });

    testWidgets('tocar num produto fecha devolvendo-o', (tester) async {
      usarTelaDeCelular(tester);
      injetor.registerSingleton<RepositorioCatalogo>(
        repositorioCatalogoDeTeste(_catalogo()),
      );
      addTearDown(() => injetor.reset());
      ProdutoCatalogo? escolhido;
      final roteador = GoRouter(
        initialLocation: '/inicio',
        routes: [
          GoRoute(
            path: '/inicio',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () async => escolhido = await context
                    .push<ProdutoCatalogo>('/importar'),
                child: const Text('abrir'),
              ),
            ),
          ),
          GoRoute(
            path: '/importar',
            builder: (_, _) => const ProdutosImportarScreen(),
          ),
        ],
      );
      addTearDown(roteador.dispose);
      await tester.pumpWidget(appDeTeste(roteador: roteador));
      await tester.pumpAndSettle();
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sabonete Ekos'));
      await tester.pumpAndSettle();

      expect(escolhido?.codigo, '2');
      expect(find.text('abrir'), findsOneWidget);
    });
  });

  test('a busca espera parar de digitar antes de consultar', () async {
    final catalogo = _catalogo();
    final cubit = ProdutosImportarCubit(
      catalogo: repositorioCatalogoDeTeste(catalogo),
      esperaBusca: const Duration(milliseconds: 30),
    );
    await _pronto();
    final inicio = catalogo.buscas.length;

    cubit
      ..alterarBusca('s')
      ..alterarBusca('sa')
      ..alterarBusca('sab');
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(catalogo.buscas.length - inicio, 1);
    expect(catalogo.buscas.last.texto, 'sab');
    await cubit.close();
  });
}
