/// Duração estimada de um serviço.
abstract final class DuracaoServico {
  /// Opções do formulário, em minutos.
  static const opcoes = [15, 30, 45, 60, 90, 120, 150, 180, 240];

  static const textoSemDuracao = 'Não informada';

  /// 90 → "1h 30min"; 60 → "1h"; 45 → "45min".
  static String curto(int minutos) {
    final horas = minutos ~/ 60;
    final resto = minutos % 60;
    if (horas == 0) return '${resto}min';
    if (resto == 0) return '${horas}h';
    return '${horas}h ${resto}min';
  }

  /// 90 → "1 hora e 30 minutos"; 30 → "30 minutos".
  static String porExtenso(int minutos) {
    final horas = minutos ~/ 60;
    final resto = minutos % 60;
    final textoHoras = horas == 1 ? '1 hora' : '$horas horas';
    if (horas == 0) return '$resto minutos';
    if (resto == 0) return textoHoras;
    return '$textoHoras e $resto minutos';
  }
}
