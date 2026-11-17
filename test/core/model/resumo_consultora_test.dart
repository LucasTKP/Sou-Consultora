import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/model/resumo_consultora.dart';

void main() {
  group('iniciais', () {
    test('primeiro e último nome', () {
      expect(ResumoConsultora.de(nome: 'Ana Paula Consultora').iniciais, 'AC');
    });

    test('nome único', () {
      expect(ResumoConsultora.de(nome: 'mariana').iniciais, 'M');
    });

    test('acentos são mantidos', () {
      expect(ResumoConsultora.de(nome: 'Íris Évora').iniciais, 'ÍÉ');
    });

    test('sem nome usa o e-mail', () {
      final resumo = ResumoConsultora.de(nome: '  ', email: 'carla.mendes@email.com');
      expect(resumo.nome, 'carla.mendes@email.com');
      expect(resumo.iniciais, 'CC');
    });

    test('sem nome nem e-mail devolve ?', () {
      expect(ResumoConsultora.de().iniciais, '?');
    });
  });

  test('foto vazia vira ausência de foto', () {
    expect(ResumoConsultora.de(nome: 'Ana', fotoUrl: ' ').temFoto, isFalse);
    expect(ResumoConsultora.de(nome: 'Ana', fotoUrl: 'https://x/y.png').temFoto, isTrue);
  });
}
