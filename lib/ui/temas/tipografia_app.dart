import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:flutter/material.dart';

abstract final class TipografiaApp {
  static const String? familia = null; // system / platform default

  static TextTheme get claro {
    const base = TextStyle(
      fontFamily: familia,
      color: CoresApp.sobreSuperficie,
      letterSpacing: -0.1,
    );

    return TextTheme(
      displayLarge: base.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
      displayMedium: base.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      displaySmall: base.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      headlineLarge: base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      headlineMedium: base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      headlineSmall: base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleLarge: base.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleMedium: base.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      titleSmall: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodyMedium: base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodySmall: base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: CoresApp.sobreSuperficieVariante,
      ),
      labelLarge: base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      labelMedium: base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      labelSmall: base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: CoresApp.sobreSuperficieVariante,
      ),
    );
  }
}
