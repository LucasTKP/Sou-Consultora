import 'package:sou_consultora/core/model/telefone.dart';

/// Telefones brasileiros com DDD.
abstract final class FormatadorTelefone {
  /// "11987654321" → "(11) 98765-4321"; "1134567890" → "(11) 3456-7890".
  /// Formata parcialmente enquanto a pessoa digita.
  static String formatar(String texto) {
    final digitos = somenteDigitos(texto);
    if (digitos.isEmpty) return '';
    if (digitos.length <= 2) return '($digitos';

    final ddd = digitos.substring(0, 2);
    final numero = digitos.substring(2);
    final corte = numero.length > 8 ? 5 : 4;
    if (numero.length <= corte) return '($ddd) $numero';
    return '($ddd) ${numero.substring(0, corte)}-${numero.substring(corte)}';
  }

  /// Mantém só os dígitos, no máximo 11 (DDD + 9 dígitos).
  static String somenteDigitos(String texto) => Telefone.digitos(texto);

  /// DDD + 8 ou 9 dígitos.
  static bool valido(String texto) => Telefone.valido(texto);
}
