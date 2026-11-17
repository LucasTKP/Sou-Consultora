// ignore_for_file: deprecated_member_use
// shadcn_ui ainda depende de package:flutter/material.dart (não material_ui).
import 'package:flutter/material.dart';

/// Tokens de cor extraídos de `telas/design-system` e conferidos nas telas
/// (login, início, clientes, vendas, a-receber).
///
/// Primária canônica do DS: `#B0396F`. Em algumas telas o header/logo usa um
/// berry mais fechado (`#902054`) — exposto como [primariaEscura].
abstract final class CoresApp {
  // —— Marca ——
  static const Color primaria = Color(0xFFB0396F);
  static const Color primariaEscura = Color(0xFF902054);
  static const Color sobrePrimaria = Color(0xFFFFFFFF);

  /// Fundo suave de botão terciário / chips leves (lilás-rosa do DS).
  static const Color primariaSuave = Color(0xFFF4E4E9);

  // —— Superfícies ——
  static const Color fundo = Color(0xFFFEF8F8);
  static const Color superficie = Color(0xFFFFFFFF);
  static const Color sobreSuperficie = Color(0xFF332D2D);
  static const Color sobreSuperficieVariante = Color(0xFF7D7D7D);
  static const Color contorno = Color(0xFFE0E0E0);

  // —— Status (badges: Em dia / A receber / Atrasado / Rascunho) ——
  static const Color sucesso = Color(0xFF00543C);
  static const Color sucessoContainer = Color(0xFFDCF4EC);

  static const Color alerta = Color(0xFF684C0C);
  static const Color alertaContainer = Color(0xFFFCF0C4);

  static const Color perigo = Color(0xFF9B1B1B);
  static const Color perigoContainer = Color(0xFFFCE4E4);

  static const Color neutro = Color(0xFF5C5555);
  static const Color neutroContainer = Color(0xFFF2EBEB);

  // —— Auth / misc ——
  static const Color botaoApple = Color(0xFF332D2D);
}
