// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_icone_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/alternador_segmentado_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_data_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/interruptor_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/seletor_quantidade_app.dart';

import '../../auxiliares/montar_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('campo de texto mostra rótulo obrigatório, opcional e erro', (
    tester,
  ) async {
    await montar(
      tester,
      const Column(
        children: [
          CampoTextoApp(rotulo: 'Nome', obrigatorio: true),
          CampoTextoApp(rotulo: 'Observações', opcional: true),
          CampoTextoApp(rotulo: 'WhatsApp', erro: 'Informe o WhatsApp'),
        ],
      ),
    );

    expect(find.textContaining('Nome *', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('Observações (Opcional)', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Informe o WhatsApp'), findsOneWidget);
  });

  testWidgets('campo de moeda devolve centavos', (tester) async {
    int? centavos;
    await montar(
      tester,
      CampoMoedaApp(rotulo: 'Valor', onChanged: (valor) => centavos = valor),
    );

    await tester.enterText(find.byType(TextField), '84250');
    expect(centavos, 84250);
    expect(find.text('842,50'), findsOneWidget);
  });

  testWidgets('campo de data mostra a data formatada', (tester) async {
    await montar(
      tester,
      CampoDataApp(
        rotulo: 'Vencimento',
        data: DateTime(2024, 5, 15),
        onChanged: (_) {},
      ),
    );
    expect(find.text('15/05/2024'), findsOneWidget);
  });

  testWidgets('seleção abre a folha, filtra e devolve o valor', (tester) async {
    String? escolhido;
    await montar(
      tester,
      CampoSelecaoApp<String>(
        rotulo: 'Cliente',
        opcoes: const ['Camila Rodrigues', 'Dona Carla'],
        rotuloDe: (opcao) => opcao,
        buscavel: true,
        onChanged: (valor) => escolhido = valor,
      ),
    );

    await tester.tap(find.byType(CampoSelecaoApp<String>));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'carla');
    await tester.pumpAndSettle();
    expect(find.text('Camila Rodrigues'), findsNothing);

    await tester.tap(find.text('Dona Carla'));
    await tester.pumpAndSettle();
    expect(escolhido, 'Dona Carla');
  });

  group('seleção com cadastro', () {
    Future<void> montarCampo(
      WidgetTester tester, {
      VoidCallback? onCadastrar,
      ValueChanged<String>? onChanged,
    }) => montar(
      tester,
      CampoSelecaoApp<String>(
        rotulo: 'Fornecedor',
        opcoes: const ['Natura', 'Avon'],
        rotuloDe: (opcao) => opcao,
        buscavel: true,
        onChanged: onChanged ?? (_) {},
        onCadastrar: onCadastrar,
        rotuloCadastrar: 'Cadastrar fornecedor',
      ),
    );

    testWidgets('não há mais a seta de atalho ao lado do campo', (
      tester,
    ) async {
      await montarCampo(tester, onCadastrar: () {});

      expect(find.byType(BotaoIconeApp), findsNothing);
      expect(find.text('Cadastrar fornecedor'), findsNothing); // só na folha
    });

    testWidgets('a folha tem o botão Cadastrar, que fecha e abre o cadastro', (
      tester,
    ) async {
      var cadastrou = 0;
      String? escolhido;
      await montarCampo(
        tester,
        onCadastrar: () => cadastrou++,
        onChanged: (v) => escolhido = v,
      );

      await tester.tap(find.byType(CampoSelecaoApp<String>));
      await tester.pumpAndSettle();
      expect(find.text('Cadastrar fornecedor'), findsOneWidget);
      expect(cadastrou, 0);

      await tester.tap(find.text('Cadastrar fornecedor'));
      await tester.pumpAndSettle();

      expect(cadastrou, 1);
      expect(escolhido, isNull); // não escolheu nenhuma opção
      expect(find.text('Natura'), findsNothing); // a folha fechou
    });

    testWidgets('escolher uma opção não aciona o cadastro', (tester) async {
      var cadastrou = 0;
      String? escolhido;
      await montarCampo(
        tester,
        onCadastrar: () => cadastrou++,
        onChanged: (v) => escolhido = v,
      );

      await tester.tap(find.byType(CampoSelecaoApp<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Avon'));
      await tester.pumpAndSettle();

      expect(escolhido, 'Avon');
      expect(cadastrou, 0);
    });

    testWidgets('sem resultado na busca, o botão continua ali', (tester) async {
      await montarCampo(tester, onCadastrar: () {});

      await tester.tap(find.byType(CampoSelecaoApp<String>));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('Nenhum resultado.'), findsOneWidget);
      expect(find.text('Cadastrar fornecedor'), findsOneWidget);
    });

    testWidgets('sem onCadastrar a folha não mostra o botão', (tester) async {
      await montarCampo(tester);

      await tester.tap(find.byType(CampoSelecaoApp<String>));
      await tester.pumpAndSettle();

      expect(find.text('Natura'), findsOneWidget);
      expect(find.text('Cadastrar fornecedor'), findsNothing);
    });
  });

  testWidgets('quantidade respeita mínimo e máximo', (tester) async {
    final mudancas = <int>[];
    await montar(
      tester,
      SeletorQuantidadeApp(valor: 1, maximo: 2, onChanged: mudancas.add),
    );

    await tester.tap(find.byTooltip('Diminuir'));
    await tester.tap(find.byTooltip('Aumentar'));
    expect(mudancas, [2]);

    await montar(
      tester,
      SeletorQuantidadeApp(valor: 2, maximo: 2, onChanged: mudancas.add),
    );
    await tester.tap(find.byTooltip('Aumentar'));
    expect(mudancas, [2]);
  });

  testWidgets('alternador troca o valor', (tester) async {
    String? selecionado;
    await montar(
      tester,
      AlternadorSegmentadoApp<String>(
        opcoes: const [
          OpcaoSegmento(valor: 'produto', rotulo: 'Produto'),
          OpcaoSegmento(valor: 'servico', rotulo: 'Serviço'),
        ],
        selecionado: 'produto',
        onChanged: (valor) => selecionado = valor,
      ),
    );

    await tester.tap(find.text('Serviço'));
    expect(selecionado, 'servico');
  });

  testWidgets('interruptor alterna pelo toque na linha', (tester) async {
    final valores = <bool>[];
    await montar(
      tester,
      InterruptorApp(
        rotulo: 'Em espera',
        descricao: 'A marca sai dos ativos',
        valor: false,
        onChanged: valores.add,
      ),
    );

    await tester.tap(find.text('Em espera'));
    await tester.tap(find.byType(Switch));

    expect(find.text('A marca sai dos ativos'), findsOneWidget);
    expect(valores, [true, true]);
  });
}
