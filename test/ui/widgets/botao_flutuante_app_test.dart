// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_flutuante_app.dart';

import '../../auxiliares/montar_app.dart';

bool _temHalo(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(BotaoFlutuanteApp),
        matching: find.byType(DecoratedBox),
      ),
    )
    .any((caixa) {
      final decoracao = caixa.decoration;
      return decoracao is BoxDecoration &&
          (decoracao.boxShadow?.isNotEmpty ?? false);
    });

double _tamanhoDoRotulo(WidgetTester tester, String rotulo) =>
    tester.widget<Text>(find.text(rotulo)).style!.fontSize!;

void main() {
  testWidgets('botão comum não tem fundinho', (tester) async {
    await montar(
      tester,
      Stack(
        children: [BotaoFlutuanteApp(rotulo: 'Novo cliente', onPressed: () {})],
      ),
    );

    expect(_temHalo(tester), isFalse);
    expect(_tamanhoDoRotulo(tester, 'Novo cliente'), 17);
  });

  testWidgets('em destaque fica maior e com fundinho (halo e sombra)', (
    tester,
  ) async {
    var toques = 0;
    await montar(
      tester,
      Stack(
        children: [
          BotaoFlutuanteApp(
            rotulo: 'Adicionar',
            destaque: true,
            onPressed: () => toques++,
          ),
        ],
      ),
    );

    expect(_temHalo(tester), isTrue);
    expect(_tamanhoDoRotulo(tester, 'Adicionar'), greaterThan(17));

    await tester.tap(find.text('Adicionar'));
    expect(toques, 1);
  });
}
