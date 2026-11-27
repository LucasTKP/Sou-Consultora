/// Regras de telefone brasileiro (DDD + 8 ou 9 dígitos).
abstract final class Telefone {
  /// Só os dígitos, no máximo 11.
  static String digitos(String texto) {
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    return digitos.length > 11 ? digitos.substring(0, 11) : digitos;
  }

  static bool valido(String texto) {
    final tamanho = texto.replaceAll(RegExp(r'\D'), '').length;
    return tamanho == 10 || tamanho == 11;
  }
}
