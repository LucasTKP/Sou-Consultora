import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/api/registro_depuracao.dart';

void main() {
  test('mascara tokens, telefone, WhatsApp, CPF e chave Pix', () {
    const corpo =
        '{"access_token":"abc","refresh_token": "def","nome":"Ana",'
        '"whatsapp":"11999990000","p_whatsapp":"11999990000",'
        '"telefone":"1133334444","cpf":"12345678900","chave_pix":"ana@pix"}';

    final mascarado = RegistroDepuracao.mascarar(corpo);

    expect(mascarado, contains('"nome":"Ana"'));
    for (final segredo in [
      'abc',
      'def',
      '1199999',
      '11333',
      '123456',
      'ana@pix',
    ]) {
      expect(mascarado, isNot(contains(segredo)));
    }
  });

  test('mascara campos com prefixo (views: cliente_whatsapp…)', () {
    const corpo =
        '{"cliente_nome":"Carla","cliente_whatsapp":"11999990001",'
        '"fornecedor_telefone":"1133334444","cliente_cpf":"12345678900"}';

    final mascarado = RegistroDepuracao.mascarar(corpo);

    expect(mascarado, contains('"cliente_whatsapp":"***"'));
    expect(mascarado, contains('"fornecedor_telefone":"***"'));
    expect(mascarado, contains('"cliente_cpf":"***"'));
    for (final segredo in ['1199999', '11333', '123456']) {
      expect(mascarado, isNot(contains(segredo)));
    }
  });

  test('mascara token de URL assinada', () {
    expect(
      RegistroDepuracao.mascarar('/object/sign/fotos/a.jpg?token=xyz.123&x=1'),
      '/object/sign/fotos/a.jpg?token=***&x=1',
    );
  });
}
