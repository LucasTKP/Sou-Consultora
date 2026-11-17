// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sou_consultora/ui/widgets/formularios/alternador_segmentado_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_data_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/seletor_quantidade_app.dart';

import '../../auxiliares/montar_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('campo de texto mostra rótulo obrigatório, opcional e erro', (tester) async {
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
    expect(find.textContaining('Observações (Opcional)', findRichText: true), findsOneWidget);
    expect(find.text('Informe o WhatsApp'), findsOneWidget);
  });

  testWidgets('campo de moeda devolve centavos', (tester) async {
    int? centavos;
    await montar(tester, CampoMoedaApp(rotulo: 'Valor', onChanged: (valor) => centavos = valor));

    await tester.enterText(find.byType(TextField), '84250');
    expect(centavos, 84250);
    expect(find.text('842,50'), findsOneWidget);
  });

  testWidgets('campo de data mostra a data formatada', (tester) async {
    await montar(tester, CampoDataApp(rotulo: 'Vencimento', data: DateTime(2024, 5, 15), onChanged: (_) {}));
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

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'carla');
    await tester.pumpAndSettle();
    expect(find.text('Camila Rodrigues'), findsNothing);

    await tester.tap(find.text('Dona Carla'));
    await tester.pumpAndSettle();
    expect(escolhido, 'Dona Carla');
  });

  testWidgets('seleção com atalho mostra o botão ao lado', (tester) async {
    var atalho = false;
    await montar(
      tester,
      CampoSelecaoApp<String>(
        rotulo: 'Fornecedor',
        opcoes: const ['Natura'],
        rotuloDe: (opcao) => opcao,
        onChanged: (_) {},
        onAtalho: () => atalho = true,
        dicaAtalho: 'Abrir fornecedores',
      ),
    );

    await tester.tap(find.byTooltip('Abrir fornecedores'));
    expect(atalho, isTrue);
  });

  testWidgets('quantidade respeita mínimo e máximo', (tester) async {
    final mudancas = <int>[];
    await montar(tester, SeletorQuantidadeApp(valor: 1, maximo: 2, onChanged: mudancas.add));

    await tester.tap(find.byTooltip('Diminuir'));
    await tester.tap(find.byTooltip('Aumentar'));
    expect(mudancas, [2]);

    await montar(tester, SeletorQuantidadeApp(valor: 2, maximo: 2, onChanged: mudancas.add));
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
}
