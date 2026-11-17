/// Quanto tempo um produto dura (alimenta o lembrete de recompra).
abstract final class Durabilidade {
  /// Opções do formulário, em dias. O banco aceita de 30 a 180.
  static const opcoes = [30, 45, 60, 90, 120, 150, 180];

  static const textoSemPrevisao = 'Sem previsão';

  /// 60 → "60 dias (2 meses)"; 30 → "30 dias (1 mês)"; 45 → "45 dias".
  static String texto(int dias) {
    if (dias % 30 != 0) return '$dias dias';
    final meses = dias ~/ 30;
    return '$dias dias (${meses == 1 ? '1 mês' : '$meses meses'})';
  }
}
