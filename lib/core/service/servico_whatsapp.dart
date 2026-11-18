import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/telefone.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre a conversa com um número no WhatsApp (app ou navegador), com uma
/// [mensagem] já escrita quando informada (ex.: cobrança).
abstract interface class ServicoWhatsapp {
  Future<Resultado<void>> abrirConversa(String whatsapp, {String? mensagem});
}

class ServicoWhatsappNativo implements ServicoWhatsapp {
  ServicoWhatsappNativo({Future<bool> Function(Uri)? abrir})
    : _abrir = abrir ?? _abrirExterno;

  final Future<bool> Function(Uri) _abrir;

  static const _falha = FalhaInesperada('Não foi possível abrir o WhatsApp');

  /// "(11) 98765-4321" → https://wa.me/5511987654321 (com `?text=` se houver mensagem)
  static Uri linkDe(String whatsapp, {String? mensagem}) => Uri.https(
    'wa.me',
    '/55${Telefone.digitos(whatsapp)}',
    mensagem == null ? null : {'text': mensagem},
  );

  @override
  Future<Resultado<void>> abrirConversa(
    String whatsapp, {
    String? mensagem,
  }) async {
    try {
      final abriu = await _abrir(linkDe(whatsapp, mensagem: mensagem));
      return abriu ? const Sucesso(null) : Erro(_falha);
    } catch (erro, pilha) {
      return Erro(_falha, causa: erro, pilha: pilha);
    }
  }

  static Future<bool> _abrirExterno(Uri link) =>
      launchUrl(link, mode: LaunchMode.externalApplication);
}
