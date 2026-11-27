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

  static final _semCentavos = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
    decimalDigits: 0,
  );

  /// 5482050 → "R$ 54.821" (reais arredondados; para totais grandes).
  static String formatarSemCentavos(int centavos) =>
      _normalizarEspacos(_semCentavos.format((centavos / 100).round()));

  /// Rótulo curto do gráfico: 98000 → "980", 540000 → "5.4k",
  /// 500000 → "5k", 125000000 → "1.3M".
  static String abreviado(int centavos) {
    final reais = centavos / 100;
    if (reais < 1000) return reais.round().toString();
    if (reais < 1000000) return '${_umaCasa(reais / 1000)}k';
    return '${_umaCasa(reais / 1000000)}M';
  }

  /// 5.43 → "5.4"; 5.0 → "5".
  static String _umaCasa(double valor) {
    final texto = valor.toStringAsFixed(1);
    return texto.endsWith('.0') ? texto.substring(0, texto.length - 2) : texto;
  }

  /// "R$ 1.234,56" → 123456. Texto sem dígitos → 0.
  static int ler(String texto) {
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return 0;
    return int.parse(digitos);
  }

  // O intl usa espaço não separável depois do "R$"; padronizamos para espaço comum.
  static String _normalizarEspacos(String texto) => texto.replaceAll(' ', ' ');
}
