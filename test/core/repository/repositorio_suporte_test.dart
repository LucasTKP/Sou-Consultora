import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/env/suporte_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/repository/repositorio_suporte.dart';

import '../../auxiliares/falsos_clientes.dart';

void main() {
  test('abre a conversa com o suporte e leva a mensagem', () async {
    final whatsapp = ServicoWhatsappFalso();
    final resultado = await RepositorioSuporte(whatsapp: whatsapp)
        .abrirConversa('Preciso de ajuda');

    expect(resultado, isA<Sucesso<void>>());
    expect(whatsapp.aberturas, [SuporteApp.whatsapp]);
    expect(whatsapp.mensagens, ['Preciso de ajuda']);
  });

  test('falha ao abrir o WhatsApp vira erro', () async {
    final whatsapp = ServicoWhatsappFalso()..abre = false;
    final resultado = await RepositorioSuporte(whatsapp: whatsapp)
        .abrirConversa('Preciso de ajuda');

    expect(resultado, isA<Erro<void>>());
  });
}
