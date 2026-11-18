import 'package:intl/intl.dart';

/// Datas em pt-BR. Exige `initializeDateFormatting('pt_BR')` no `main`.
abstract final class FormatadorData {
  static final _curta = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _porExtenso = DateFormat("d 'de' MMMM 'de' y", 'pt_BR');
  static final _mesAno = DateFormat("MMMM 'de' y", 'pt_BR');
  static final _diaMes = DateFormat("d 'de' MMMM", 'pt_BR');

  /// 15/05/2024
  static String curta(DateTime data) => _curta.format(data);

  /// 15 de outubro de 2024
  static String porExtenso(DateTime data) => _porExtenso.format(data);

  /// novembro de 2024
  static String mesAno(DateTime data) => _mesAno.format(data);

  static const _mesesCurtos = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  /// "mar/2023"
  static String mesAnoCurto(DateTime data) =>
      '${_mesesCurtos[data.month - 1]}/${data.year}';

  /// "14 de novembro" (aniversário, sem o ano).
  static String diaMes(DateTime data) => _diaMes.format(data);

  /// "15/10".
  static String diaMesNumerico(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}';

  /// "15/05/2024" → DateTime. Texto incompleto ou data inexistente → null.
  static DateTime? ler(String texto) {
    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(texto)) return null;
    final [dia, mes, ano] = texto.split('/').map(int.parse).toList();
    final data = DateTime(ano, mes, dia);
    if (data.day != dia || data.month != mes) return null;
    return data;
  }

  /// "hoje", "ontem", "amanhã", "há 18 dias", "em 3 dias" — relativo a [hoje].
  static String relativo(DateTime data, {required DateTime hoje}) {
    final dias = _diaSemHora(data).difference(_diaSemHora(hoje)).inDays;
    return switch (dias) {
      0 => 'hoje',
      -1 => 'ontem',
      1 => 'amanhã',
      < 0 => 'há ${-dias} dias',
      _ => 'em $dias dias',
    };
  }

  /// "Hoje • 14:30", "Ontem • 16:45", "12/11 • 11:20" (outro ano: "12/11/2025 • 11:20").
  static String quando(DateTime momento, {required DateTime hoje}) {
    final hora =
        '${momento.hour.toString().padLeft(2, '0')}:'
        '${momento.minute.toString().padLeft(2, '0')}';
    final dias = _diaSemHora(hoje).difference(_diaSemHora(momento)).inDays;
    final dia = momento.day.toString().padLeft(2, '0');
    final mes = momento.month.toString().padLeft(2, '0');
    final data = switch (dias) {
      0 => 'Hoje',
      1 => 'Ontem',
      _ when momento.year == hoje.year => '$dia/$mes',
      _ => '$dia/$mes/${momento.year}',
    };
    return '$data • $hora';
  }

  /// "Nov / 2026".
  static String mesAnoAbreviado(int ano, int mes) =>
      '${_mesesCurtos[mes - 1][0].toUpperCase()}${_mesesCurtos[mes - 1].substring(1)} / $ano';

  static DateTime _diaSemHora(DateTime data) =>
      DateTime.utc(data.year, data.month, data.day);
}
