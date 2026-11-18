import 'package:sou_consultora/core/model/lembrete_recompra.dart';

/// Mensagem do lembrete de recompra no WhatsApp.
abstract final class MensagemRecompra {
  /// Oi, Carla! Tudo bem? 😊
  /// Já faz 62 dias da sua compra de Lily Eau de Parfum 75ml. Deve estar
  /// acabando por aí! Quer que eu separe mais um para você?
  /// (Sem artigo: o nome do produto pode ser masculino ou feminino.)
  /// Beijos! 💖 Ana
  static String montar({
    required LembreteRecompra lembrete,
    required int diasDesdeCompra,
    required String nomeConsultora,
  }) {
    final primeiroNome = lembrete.clienteNome
        .trim()
        .split(RegExp(r'\s+'))
        .first;
    final quando = diasDesdeCompra == 1 ? '1 dia' : '$diasDesdeCompra dias';
    final assinatura = nomeConsultora.trim().split(RegExp(r'\s+')).first;
    return 'Oi, $primeiroNome! Tudo bem? 😊\n'
        'Já faz $quando da sua compra de ${lembrete.produtoNome}. '
        'Deve estar acabando por aí! Quer que eu separe mais um para você?\n'
        '\n'
        'Beijos! 💖 $assinatura';
  }
}
