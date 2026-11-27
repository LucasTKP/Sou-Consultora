/// Percentual no app é sempre em **centésimos inteiros** (1250 = 12,5%).
abstract final class FormatadorPercentual {
  /// 1000 → "10"; 1250 → "12,5"; 0 → "".
  static String formatar(int centesimos) {
    if (centesimos == 0) return '';
    final texto = (centesimos / 100).toStringAsFixed(2);
    return texto.replaceFirst(RegExp(r'\.?0+$'), '').replaceFirst('.', ',');
  }

  /// Complemento do valor do desconto: " (10%)"; vazio quando foi em R$.
  static String complemento(int? centesimos) =>
      centesimos == null ? '' : ' (${formatar(centesimos)}%)';

  /// "12,5" → 1250. Texto sem dígitos → 0.
  static int ler(String texto) {
    final valor = double.tryParse(texto.replaceFirst(',', '.')) ?? 0;
    return (valor * 100).round();
  }
}
