import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/ui/temas/espacos_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/rodape_seguro.dart';

void main() {
  test('a folga inferior é de 16 px', () {
    expect(EspacosApp.folgaInferior, 16);
  });

  testWidgets('rodapé seguro soma a área do aparelho à folga', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 48)),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: RodapeSeguro(child: SizedBox(key: Key('botao'), height: 56)),
          ),
        ),
      ),
    );

    final tela = tester.view.physicalSize / tester.view.devicePixelRatio;
    final botao = tester.getRect(find.byKey(const Key('botao')));
    // 48 da barra do aparelho + 24 de folga, e não o maior dos dois.
    expect(tela.height - botao.bottom, 48 + 24);
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
