import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/model/dica_app.dart';
import 'package:sou_consultora/core/repository/repositorio_catalogo.dart';
import 'package:sou_consultora/core/repository/repositorio_categorias.dart';
import 'package:sou_consultora/core/repository/repositorio_dicas.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/ui/modules/produtos/formulario/produtos_formulario_screen.dart';
import 'package:sou_consultora/ui/modules/produtos/importar/produtos_importar_screen.dart';

import '../../auxiliares/falsos_catalogo.dart';
import '../../auxiliares/falsos_dicas.dart';
import '../../auxiliares/falsos_fornecedores.dart';
import '../../auxiliares/falsos_produtos.dart';
import '../../auxiliares/montar_app.dart';

/// Abre o cadastro de produto (ou a edição) com o passo a passo ligado.
Future<GoRouter> _abrir(
  WidgetTester tester,
  ServicoDicasFalso dicas, {
  String caminho = '/produtos/novo',
}) async {
  usarTelaDeCelular(tester);
  injetor
    ..registerSingleton<RepositorioProdutos>(
      repositorioProdutosDeTeste(
        ServicoProdutosFalso(resumos: [produtoDto('p1', 'Batom')]),
      ),
    )
    ..registerSingleton<RepositorioFornecedores>(
      repositorioFornecedoresDeTeste(
        ServicoFornecedoresFalso(resumos: [fornecedorDto('m1', 'Natura')]),
      ),
    )
    ..registerSingleton<RepositorioCategorias>(repositorioCategoriasDeTeste())
    ..registerSingleton<RepositorioCatalogo>(
      repositorioCatalogoDeTeste(
        ServicoCatalogoFalso(
          itens: [catalogoDto('174918', 'Balm labial ameixa')],
        ),
      ),
    )
    ..registerSingleton<RepositorioDicas>(repositorioDicasDeTeste(dicas));
  final roteador = GoRouter(
    initialLocation: '/inicio',
    routes: [
      GoRoute(
        path: '/inicio',
        builder: (_, _) => const Scaffold(body: Text('anterior')),
      ),
      GoRoute(
        path: '/produtos/novo',
        builder: (_, _) => const ProdutosFormularioScreen(),
      ),
      GoRoute(
        path: '/produtos/importar',
        builder: (_, _) => const ProdutosImportarScreen(),
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
  await _esperar(tester);
  return roteador;
}

/// Deixa passar a carga, os atrasos do passo a passo e as animações dele.
Future<void> _esperar(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Toca fora do destaque (no canto) para ir ao passo seguinte.
Future<void> _proximo(WidgetTester tester) async {
  await tester.tapAt(const Offset(8, 8));
  await _esperar(tester);
}

void main() {
  group('passo a passo da importação (cadastro de produto)', () {
    testWidgets('no produto novo apresenta o botão Importar, uma vez só', (
      tester,
    ) async {
      final dicas = ServicoDicasFalso();
      await _abrir(tester, dicas);

      expect(find.text('Cadastre mais rápido'), findsOneWidget);
      expect(dicas.vistas, isEmpty); // só conta como visto ao terminar

      await _proximo(tester);
      expect(find.text('Cadastre mais rápido'), findsNothing);
      expect(dicas.vistas, {DicaApp.importarNoFormulario});
    });

    testWidgets('quem já viu não vê de novo', (tester) async {
      final dicas = ServicoDicasFalso(vistas: {DicaApp.importarNoFormulario});
      await _abrir(tester, dicas);

      expect(find.text('Cadastre mais rápido'), findsNothing);
      expect(find.text('Importar do catálogo'), findsOneWidget);
    });

    testWidgets('na edição de um produto não aparece', (tester) async {
      final dicas = ServicoDicasFalso();
      await _abrir(tester, dicas, caminho: '/produtos/p1/editar');

      expect(find.text('Cadastre mais rápido'), findsNothing);
      expect(dicas.vistas, isEmpty);
    });

    testWidgets('importar um produto leva ao Continuar, uma vez só', (
      tester,
    ) async {
      final dicas = ServicoDicasFalso(
        vistas: {DicaApp.importarNoFormulario, DicaApp.importarNaLista},
      );
      await _abrir(tester, dicas);
      expect(find.text('Quase pronto!'), findsNothing);

      await tester.tap(find.text('Importar do catálogo'));
      await _esperar(tester);
      await tester.tap(find.text('Balm labial ameixa'));
      await _esperar(tester);

      expect(find.text('Quase pronto!'), findsOneWidget);
      await _proximo(tester);
      expect(dicas.vistas, contains(DicaApp.continuarAposImportar));
    });
  });
}
