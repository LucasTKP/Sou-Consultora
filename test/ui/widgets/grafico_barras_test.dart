import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/ui/widgets/graficos/grafico_barras_app.dart';

void main() {
  Widget montar({double escala = 1}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(escala)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: GraficoBarrasApp(
                destaque: 2,
                rotuloDestaque: 'R\$ 5,4 mil',
                barras: const [
                  BarraGrafico(rotulo: 'Set', valor: 100, descricao: 'a'),
                  BarraGrafico(rotulo: 'Out', valor: 200, descricao: 'b'),
                  BarraGrafico(rotulo: 'Nov', valor: 540, descricao: 'c'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  for (final escala in [1.0, 2.0]) {
    testWidgets('último mês é o maior e a fonte é ${escala}x: nada é cortado', (
      tester,
    ) async {
      await tester.pumpWidget(montar(escala: escala));

      expect(tester.takeException(), isNull);
      final grafico = tester.getRect(find.byType(GraficoBarrasApp));
      final valor = tester.getRect(find.text('R\$ 5,4 mil'));
      final mes = tester.getRect(find.text('Nov'));
      expect(valor.top, greaterThanOrEqualTo(grafico.top));
      expect(mes.bottom, lessThanOrEqualTo(grafico.bottom));
    });
  }
}
