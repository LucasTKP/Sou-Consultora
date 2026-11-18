/// Situação do lembrete de recompra (calculada, nunca gravada).
enum SituacaoLembrete {
  cicloIdeal('Ciclo ideal'),
  acabando('Acabando!');

  const SituacaoLembrete(this.rotulo);

  final String rotulo;
}

/// Última compra de um produto com duração prevista por uma cliente
/// (view `lembretes_recompra`).
class LembreteRecompra {
  const LembreteRecompra({
    required this.clienteId,
    required this.clienteNome,
    required this.clienteWhatsapp,
    required this.produtoId,
    required this.produtoNome,
    required this.durabilidadeDias,
    required this.ultimaCompra,
  });

  final String clienteId;
  final String clienteNome;
  final String clienteWhatsapp;
  final String produtoId;
  final String produtoNome;
  final int durabilidadeDias;

  /// Dia da última compra (sem hora).
  final DateTime ultimaCompra;

  /// Começa a lembrar esta quantidade de dias antes da previsão.
  static const diasAntes = 7;

  /// Para de lembrar esta quantidade de dias depois da previsão.
  static const diasDepois = 60;

  /// Dia em que o produto deve acabar.
  /// (Somado pelo calendário: `Duration` erraria um dia em fuso com horário
  /// de verão.)
  DateTime get previsao => DateTime(
    ultimaCompra.year,
    ultimaCompra.month,
    ultimaCompra.day + durabilidadeDias,
  );

  /// Dias desde a previsão (negativo = ainda não chegou). Quanto maior, mais
  /// urgente.
  int diasDesdePrevisao({required DateTime hoje}) => _diasEntre(previsao, hoje);

  int diasDesdeCompra({required DateTime hoje}) =>
      _diasEntre(ultimaCompra, hoje);

  /// "Ciclo ideal" de 7 dias antes até a previsão; "Acabando!" depois, até
  /// 60 dias; null fora da janela (cedo demais ou passou).
  SituacaoLembrete? situacao({required DateTime hoje}) {
    final dias = diasDesdePrevisao(hoje: hoje);
    if (dias < -diasAntes || dias > diasDepois) return null;
    return dias <= 0 ? SituacaoLembrete.cicloIdeal : SituacaoLembrete.acabando;
  }

  /// Dias de calendário de [de] até [ate] (em UTC, sem horário de verão).
  static int _diasEntre(DateTime de, DateTime ate) => DateTime.utc(
    ate.year,
    ate.month,
    ate.day,
  ).difference(DateTime.utc(de.year, de.month, de.day)).inDays;
}
