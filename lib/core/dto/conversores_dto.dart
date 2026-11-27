/// Conversões comuns dos valores que chegam do PostgREST.
abstract final class ConversoresDto {
  /// `numeric` chega como número ou texto ("120.5") → centavos (12050).
  static int centavos(Object? valor) {
    if (valor == null) return 0;
    final numero = valor is num ? valor : num.parse(valor.toString());
    return (numero * 100).round();
  }

  /// `date` ("1990-05-10") → data local, sem hora.
  static DateTime? data(Object? valor) {
    if (valor == null) return null;
    final lida = DateTime.parse(valor as String);
    return DateTime(lida.year, lida.month, lida.day);
  }

  /// `timestamptz` → horário local.
  static DateTime? momento(Object? valor) =>
      valor == null ? null : DateTime.parse(valor as String).toLocal();

  /// Data → "aaaa-mm-dd" (para gravar em coluna `date`).
  static String? textoData(DateTime? data) {
    if (data == null) return null;
    String doisDigitos(int n) => n.toString().padLeft(2, '0');
    return '${data.year.toString().padLeft(4, '0')}-${doisDigitos(data.month)}-${doisDigitos(data.day)}';
  }
}
