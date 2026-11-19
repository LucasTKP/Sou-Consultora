import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/model/versao_app.dart';
import 'package:sou_consultora/core/model/versoes_minimas.dart';

void main() {
  group('VersaoApp.tentarLer', () {
    test('lê maior.menor.correção e ignora build e sufixo', () {
      expect(VersaoApp.tentarLer('1.2.3'), const VersaoApp(1, 2, 3));
      expect(VersaoApp.tentarLer('1.2.3+45'), const VersaoApp(1, 2, 3));
      expect(VersaoApp.tentarLer('2.0.0-beta'), const VersaoApp(2, 0, 0));
    });

    test('partes faltantes valem zero', () {
      expect(VersaoApp.tentarLer('1.4'), const VersaoApp(1, 4, 0));
      expect(VersaoApp.tentarLer('3'), const VersaoApp(3, 0, 0));
    });

    test('texto inválido vira null', () {
      for (final texto in ['', 'abc', '1.x.2', '1.2.3.4', '-1.0.0', '1..2']) {
        expect(VersaoApp.tentarLer(texto), isNull, reason: texto);
      }
    });
  });

  group('comparação', () {
    test('compara numericamente, não como texto', () {
      expect(
        VersaoApp.tentarLer('1.10.0')!.abaixoDe(const VersaoApp(1, 9, 0)),
        isFalse,
      );
      expect(
        const VersaoApp(1, 9, 9).abaixoDe(const VersaoApp(1, 10, 0)),
        isTrue,
      );
      expect(
        const VersaoApp(0, 9, 9).abaixoDe(const VersaoApp(1, 0, 0)),
        isTrue,
      );
    });

    test('versão igual não está abaixo', () {
      expect(
        const VersaoApp(1, 0, 0).abaixoDe(const VersaoApp(1, 0, 0)),
        isFalse,
      );
    });
  });

  group('VersoesMinimas', () {
    const minimas = VersoesMinimas(
      android: VersaoApp(2, 0, 0),
      ios: VersaoApp(1, 5, 0),
    );

    test('exige atualização só abaixo do mínimo da plataforma', () {
      const v = VersaoApp(1, 9, 0);
      expect(minimas.exigeAtualizacao(v, PlataformaApp.android), isTrue);
      expect(minimas.exigeAtualizacao(v, PlataformaApp.ios), isFalse);
    });

    test('sem mínimo definido, nunca exige', () {
      expect(
        const VersoesMinimas().exigeAtualizacao(
          const VersaoApp(0, 0, 1),
          PlataformaApp.android,
        ),
        isFalse,
      );
    });
  });
}
