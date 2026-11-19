import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/model/versoes_minimas.dart';
import 'package:sou_consultora/ui/formatadores/mensagem_suporte.dart';

void main() {
  test('o pedido de apagar a conta é a mensagem combinada', () {
    expect(
      MensagemSuporte.apagarConta,
      'Quero apagar minha conta no app "Sou Consultora"',
    );
  });

  test('leva o nome, a versão e o sistema do aparelho', () {
    final texto = MensagemSuporte.montar(
      nomeConsultora: ' Ana Paula ',
      versao: '1.2.0',
      plataforma: PlataformaApp.android,
    );
    expect(
      texto,
      'Olá! Preciso de ajuda com o app Sou Consultora.\n'
      '\n'
      'Nome: Ana Paula\n'
      'App: 1.2.0 (Android)\n'
      '\n'
      'Meu problema:',
    );
  });

  test('iPhone no iOS', () {
    expect(
      MensagemSuporte.montar(
        nomeConsultora: 'Ana',
        versao: '1.0.0',
        plataforma: PlataformaApp.ios,
      ),
      contains('App: 1.0.0 (iPhone)'),
    );
  });

  test('sem nome nem versão fica só o pedido de ajuda', () {
    expect(
      MensagemSuporte.montar(nomeConsultora: '  '),
      'Olá! Preciso de ajuda com o app Sou Consultora.\n\nMeu problema:',
    );
  });

  test('só a versão, sem sistema', () {
    final texto = MensagemSuporte.montar(nomeConsultora: '', versao: '1.0.0');
    expect(texto, contains('App: 1.0.0'));
    expect(texto, isNot(contains('(')));
    expect(texto, isNot(contains('Nome:')));
  });
}
