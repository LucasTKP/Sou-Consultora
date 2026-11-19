import 'package:sou_consultora/core/env/suporte_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/service/servico_whatsapp.dart';

/// Fala com o suporte do app pelo WhatsApp (pedidos de ajuda e de apagar conta).
class RepositorioSuporte {
  RepositorioSuporte({required this._whatsapp});

  final ServicoWhatsapp _whatsapp;

  /// Abre a conversa com o suporte, com a [mensagem] já escrita.
  Future<Resultado<void>> abrirConversa(String mensagem) =>
      _whatsapp.abrirConversa(SuporteApp.whatsapp, mensagem: mensagem);
}
