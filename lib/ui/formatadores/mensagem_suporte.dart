import 'package:sou_consultora/core/model/versoes_minimas.dart';

/// Mensagem que abre a conversa com o suporte no WhatsApp: já leva quem é a
/// consultora e a versão do app, para o suporte entender o problema.
abstract final class MensagemSuporte {
  /// Pedido de exclusão da conta, enviado ao suporte pelo WhatsApp.
  static const apagarConta = 'Quero apagar minha conta no app "Sou Consultora"';

  /// Olá! Preciso de ajuda com o app Sou Consultora.
  ///
  /// Nome: Ana Paula
  /// App: 1.0.0 (Android)
  /// Erro: Não foi possível carregar as clientes.
  ///
  /// Meu problema:
  static String montar({
    required String nomeConsultora,
    String? versao,
    PlataformaApp? plataforma,
    String? detalhe,
  }) {
    final erro = detalhe?.trim() ?? '';
    final nome = nomeConsultora.trim();
    final sistema = switch (plataforma) {
      PlataformaApp.android => 'Android',
      PlataformaApp.ios => 'iPhone',
      null => null,
    };
    final app = [?versao, if (sistema != null) '($sistema)'].join(' ');
    return [
      'Olá! Preciso de ajuda com o app Sou Consultora.',
      '',
      if (nome.isNotEmpty) 'Nome: $nome',
      if (app.isNotEmpty) 'App: $app',
      if (erro.isNotEmpty) 'Erro: $erro',
      if (nome.isNotEmpty || app.isNotEmpty || erro.isNotEmpty) '',
      'Meu problema:',
    ].join('\n');
  }
}
