// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/repository/repositorio_categorias.dart';
import 'package:sou_consultora/core/repository/repositorio_servicos.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/servicos/detalhes/servicos_detalhes_screen.dart';
import 'package:sou_consultora/ui/modules/servicos/formulario/servicos_formulario_screen.dart';
import 'package:sou_consultora/ui/modules/servicos/lista/servicos_lista_screen.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';

import '../../auxiliares/falsos_produtos.dart';
import '../../auxiliares/falsos_servicos.dart';
import '../../auxiliares/montar_app.dart';

Future<void> _abrir(
  WidgetTester tester,
  ServicoServicosFalso servico,
  String caminho,
) async {
  usarTelaDeCelular(tester);
  injetor
    ..registerSingleton<RepositorioServicos>(
      repositorioServicosDeTeste(servico),
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
        path: '/servicos',
        builder: (_, _) => const Scaffold(body: ServicosListaScreen()),
      ),
      GoRoute(
        path: '/servicos/novo',
        builder: (_, _) => const ServicosFormularioScreen(),
      ),
      GoRoute(
        path: '/servicos/:id',
        builder: (_, e) =>
            ServicosDetalhesScreen(idServico: e.pathParameters['id']!),
      ),
      GoRoute(
        path: '/servicos/:id/editar',
        builder: (_, e) =>
            ServicosFormularioScreen(idServico: e.pathParameters['id']),
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

  group('Lista', () {
    testWidgets('contador, cards, filtro de categoria e abre o detalhe', (
      tester,
    ) async {
      await _abrir(
        tester,
        ServicoServicosFalso(
          resumos: [
            servicoDto('1', 'Manicure', preco: 6500),
            servicoDto(
              '2',
              'Maquiagem Social',
              categoriaId: 's2',
              categoriaNome: 'Maquiagem',
            ),
          ],
        ),
        '/servicos',
      );

      expect(find.text('2 serviços'), findsOneWidget);
      // Segunda linha: categoria em cor e o preço por último (sem selo).
      expect(
        find.textContaining(
          'Unhas · ${FormatadorMoeda.formatar(6500)}',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('UNHAS'), findsNothing);

      await tester.tap(find.text('Todos os serviços'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maquiagem (1)').last);
      await tester.pumpAndSettle();
      expect(find.text('Manicure'), findsNothing);

      await tester.tap(find.text('Maquiagem Social'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhes do Serviço'), findsOneWidget);
    });

    testWidgets('vazio e erro', (tester) async {
      final servico = ServicoServicosFalso()..falharRede = true;
      await _abrir(tester, servico, '/servicos');
      expect(find.text('Tentar novamente'), findsOneWidget);

      servico.falharRede = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum serviço ainda'), findsOneWidget);
      expect(find.text('Cadastrar serviço'), findsOneWidget);
      expect(find.text('Novo serviço'), findsNothing);
    });
  });

  group('Formulário', () {
    testWidgets('obrigatórios, lucro e salvar', (tester) async {
      final servico = ServicoServicosFalso();
      await _abrir(tester, servico, '/servicos/novo');
      expect(find.text('Cadastrar Serviço'), findsOneWidget);

      await tester.tap(find.text('Salvar Serviço'));
      await tester.pumpAndSettle();
      expect(find.text('Informe o nome do serviço'), findsOneWidget);
      expect(find.text('Escolha a categoria'), findsWidgets);
      expect(servico.salvos, isEmpty);

      await tester.enterText(find.byType(EditableText).first, 'Maquiagem');
      await tester.tap(find.text('Escolha a categoria').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unhas').last);
      await tester.pumpAndSettle();
      final moedas = find.descendant(
        of: find.byType(CampoMoedaApp),
        matching: find.byType(EditableText),
      );
      await tester.enterText(moedas.at(0), '15000');
      await tester.enterText(moedas.at(1), '3000');
      await tester.pumpAndSettle();
      expect(find.text('Lucro:'), findsOneWidget);
      expect(find.text(FormatadorMoeda.formatar(12000)), findsOneWidget);

      await tester.tap(find.text('Salvar Serviço'));
      await tester.pumpAndSettle();
      expect(find.text('anterior'), findsOneWidget);
      final salvo = servico.salvos.single.servico;
      expect(salvo.precoCobradoCentavos, 15000);
      expect(salvo.custoMateriaisCentavos, 3000);
      expect(salvo.categoriaId, 's1');
    });
  });

  group('Detalhes', () {
    testWidgets('preço, lucro, duração e vazios omitidos; sem excluir', (
      tester,
    ) async {
      await _abrir(
        tester,
        ServicoServicosFalso(
          resumos: [
            servicoDto(
              '1',
              'Maquiagem Social',
              preco: 15000,
              custo: 3500,
              duracao: 90,
              categoriaId: 's2',
              categoriaNome: 'Maquiagem',
            ),
            servicoDto('2', 'Manicure', preco: 6500),
          ],
        ),
        '/servicos/1',
      );

      expect(find.text('Lucro'), findsOneWidget);
      expect(find.text(FormatadorMoeda.formatar(11500)), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('1h 30min (90 min)'), findsOneWidget);
      expect(find.text('OBSERVAÇÕES / DESCRIÇÃO'), findsNothing);
      expect(find.textContaining('Excluir'), findsNothing);
    });
  });
}
