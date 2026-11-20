// ignore_for_file: deprecated_member_use
import 'package:flutter/services.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/formatadores/formatador_telefone.dart';

/// Digitação de valor: os dígitos entram pela direita ("1" → "0,01", "123" → "1,23").
class MascaraMoeda extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antigo,
    TextEditingValue novo,
  ) {
    final texto = FormatadorMoeda.formatarSemSimbolo(
      FormatadorMoeda.ler(novo.text),
    );
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// (11) 98765-4321
class MascaraTelefone extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antigo,
    TextEditingValue novo,
  ) {
    final texto = FormatadorTelefone.formatar(novo.text);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// 123.456.789-09
class MascaraCpf extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antigo,
    TextEditingValue novo,
  ) {
    final texto = formatar(novo.text);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }

  /// "12345678909" → "123.456.789-09" (parcial enquanto digita).
  static String formatar(String texto) {
    var digitos = texto.replaceAll(RegExp(r'\D'), '');
    if (digitos.length > 11) digitos = digitos.substring(0, 11);
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digitos[i]);
    }
    return buffer.toString();
  }
}

/// dd/MM/aaaa
class MascaraData extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antigo,
    TextEditingValue novo,
  ) {
    final texto = formatar(novo.text);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }

  static String formatar(String texto) {
    var digitos = texto.replaceAll(RegExp(r'\D'), '');
    if (digitos.length > 8) digitos = digitos.substring(0, 8);
    final partes = <String>[
      if (digitos.isNotEmpty) digitos.substring(0, digitos.length.clamp(0, 2)),
      if (digitos.length > 2) digitos.substring(2, digitos.length.clamp(2, 4)),
      if (digitos.length > 4) digitos.substring(4),
    ];
    return partes.join('/');
  }
}

/// 00000-000
class MascaraCep extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antigo,
    TextEditingValue novo,
  ) {
    final texto = formatar(novo.text);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }

  /// "01001000" → "01001-000" (parcial enquanto digita).
  static String formatar(String texto) {
    var digitos = texto.replaceAll(RegExp(r'\D'), '');
    if (digitos.length > 8) digitos = digitos.substring(0, 8);
    if (digitos.length <= 5) return digitos;
    return '${digitos.substring(0, 5)}-${digitos.substring(5)}';
  }
}
