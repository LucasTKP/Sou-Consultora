import 'package:intl/intl.dart';

/// Dinheiro no app é sempre em **centavos inteiros** (sem `double`).
abstract final class FormatadorMoeda {
  static final _comSimbolo = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
    decimalDigits: 2,
  );
  static final _semSimbolo = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

  /// 123456 → "R$ 1.234,56"
  static String formatar(int centavos) =>
      _normalizarEspacos(_comSimbolo.format(centavos / 100));

  /// 123456 → "1.234,56"
  static String formatarSemSimbolo(int centavos) =>
      _normalizarEspacos(_semSimbolo.format(centavos / 100)).trim();

  /// "R$ 1.234,56" → 123456. Texto sem dígitos → 0.
  static int ler(String texto) {
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return 0;
    return int.parse(digitos);
  }

  // O intl usa espaço não separável depois do "R$"; padronizamos para espaço comum.
  static String _normalizarEspacos(String texto) => texto.replaceAll(' ', ' ');
}
