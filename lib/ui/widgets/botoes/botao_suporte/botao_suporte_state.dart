/// Estado do botão "Falar com o suporte".
class BotaoSuporteState {
  const BotaoSuporteState({this.abrindo = false, this.erro});

  final bool abrindo;

  /// Mensagem amigável quando o WhatsApp não abre; o botão mostra e limpa.
  final String? erro;
}
