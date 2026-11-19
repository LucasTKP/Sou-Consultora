import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/ui/temas/espacos_app.dart';

void main() {
  test('o rodapé ganha 16 px a mais embaixo', () {
    expect(EspacosApp.folgaInferior, 16);
    expect(EspacosApp.margemRodape.bottom, 24 + 16);
    expect(EspacosApp.margemRodape.left, 24);
    expect(EspacosApp.margemRodape.right, 24);
  });

  testWidgets('botão flutuante soma a barra do app, a margem e a folga', (
    tester,
  ) async {
    late double base;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 80)),
        child: Builder(
          builder: (context) {
            base = EspacosApp.baseDoBotaoFlutuante(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(base, 80 + 16 + 16);
  });
}
