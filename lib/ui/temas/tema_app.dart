// ignore_for_file: deprecated_member_use
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/temas/cores_status_app.dart';
import 'package:sou_consultora/ui/temas/tipografia_app.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

abstract final class TemaApp {
  static const ShadColorScheme esquemaShadClaro = ShadColorScheme(
    background: CoresApp.fundo,
    foreground: CoresApp.sobreSuperficie,
    card: CoresApp.superficie,
    cardForeground: CoresApp.sobreSuperficie,
    popover: CoresApp.superficie,
    popoverForeground: CoresApp.sobreSuperficie,
    primary: CoresApp.primaria,
    primaryForeground: CoresApp.sobrePrimaria,
    secondary: CoresApp.primariaSuave,
    secondaryForeground: CoresApp.primariaEscura,
    muted: CoresApp.primariaSuave,
    mutedForeground: CoresApp.sobreSuperficieVariante,
    accent: CoresApp.primariaSuave,
    accentForeground: CoresApp.primariaEscura,
    destructive: CoresApp.perigo,
    destructiveForeground: CoresApp.sobrePrimaria,
    border: CoresApp.contorno,
    input: CoresApp.contorno,
    ring: CoresApp.primaria,
    selection: CoresApp.primariaSuave,
  );

  /// Tema Shad usado no [ShadApp].
  static final ShadThemeData temaShadClaro = ShadThemeData(
    brightness: Brightness.light,
    colorScheme: esquemaShadClaro,
    radius: BorderRadius.circular(12),
    // Botões altos e com letra grande (público com leitura confortável).
    buttonSizesTheme: const ShadButtonSizesTheme(
      regular: ShadButtonSizeTheme(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      sm: ShadButtonSizeTheme(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      lg: ShadButtonSizeTheme(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
    ),
    primaryButtonTheme: _temaBotao,
    secondaryButtonTheme: _temaBotao,
    destructiveButtonTheme: _temaBotao,
    outlineButtonTheme: _temaBotao,
    ghostButtonTheme: _temaBotao,
  );

  static const ShadButtonTheme _temaBotao = ShadButtonTheme(
    textStyle: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
  );

  /// Tema Material (AppBar, FAB, NavigationBar, inputs Material).
  ///
  /// No Flutter 3.50+, `ColorScheme.light` não aceita mais parâmetros como
  /// `secondaryContainer` — o caminho suportado é [ColorScheme.fromSeed].
  static ThemeData get claro {
    final esquemaCores = ColorScheme.fromSeed(
      seedColor: CoresApp.primaria,
      brightness: Brightness.light,
      primary: CoresApp.primaria,
      onPrimary: CoresApp.sobrePrimaria,
      primaryContainer: CoresApp.primariaSuave,
      onPrimaryContainer: CoresApp.primariaEscura,
      secondary: CoresApp.primariaEscura,
      onSecondary: CoresApp.sobrePrimaria,
      secondaryContainer: CoresApp.primariaSuave,
      onSecondaryContainer: CoresApp.primariaEscura,
      error: CoresApp.perigo,
      onError: CoresApp.sobrePrimaria,
      errorContainer: CoresApp.perigoContainer,
      onErrorContainer: CoresApp.perigo,
      surface: CoresApp.superficie,
      onSurface: CoresApp.sobreSuperficie,
      onSurfaceVariant: CoresApp.sobreSuperficieVariante,
      outline: CoresApp.contorno,
      outlineVariant: CoresApp.primariaSuave,
    );

    final tipografia = TipografiaApp.claro;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: esquemaCores,
      textTheme: tipografia,
      primaryTextTheme: tipografia.apply(
        bodyColor: CoresApp.sobrePrimaria,
        displayColor: CoresApp.sobrePrimaria,
      ),
      scaffoldBackgroundColor: CoresApp.fundo,
      iconTheme: const IconThemeData(size: 24, color: CoresApp.sobreSuperficie),
      primaryIconTheme: const IconThemeData(
        size: 24,
        color: CoresApp.sobrePrimaria,
      ),
      extensions: const [CoresStatusApp.claro],
      appBarTheme: AppBarTheme(
        backgroundColor: CoresApp.primaria,
        foregroundColor: CoresApp.sobrePrimaria,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: tipografia.titleLarge?.copyWith(
          color: CoresApp.sobrePrimaria,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: CoresApp.primaria,
        foregroundColor: CoresApp.sobrePrimaria,
        iconSize: 24,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: CoresApp.primaria,
          foregroundColor: CoresApp.sobrePrimaria,
          textStyle: tipografia.labelLarge,
          iconSize: 24,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CoresApp.primaria,
          side: const BorderSide(color: CoresApp.primaria),
          textStyle: tipografia.labelLarge,
          iconSize: 24,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(iconSize: 24),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CoresApp.primaria,
          textStyle: tipografia.labelLarge,
          iconSize: 24,
        ),
      ),
      cardTheme: CardThemeData(
        color: CoresApp.superficie,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CoresApp.superficie,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CoresApp.contorno),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CoresApp.contorno),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CoresApp.primaria, width: 1.5),
        ),
        labelStyle: tipografia.bodyMedium?.copyWith(
          color: CoresApp.sobreSuperficieVariante,
        ),
        hintStyle: tipografia.bodyMedium?.copyWith(
          color: CoresApp.sobreSuperficieVariante,
        ),
      ),
      dividerTheme: const DividerThemeData(color: CoresApp.contorno),
      dialogTheme: DialogThemeData(
        backgroundColor: CoresApp.superficie,
        surfaceTintColor: Colors.transparent,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: CoresApp.superficie,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: CoresApp.superficie,
        headerForegroundColor: CoresApp.sobreSuperficie,
        dividerColor: CoresApp.contorno,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CoresApp.superficie,
        indicatorColor: CoresApp.primariaSuave,
        labelTextStyle: WidgetStateProperty.resolveWith((estados) {
          final ativo = estados.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 13,
            fontWeight: ativo ? FontWeight.w600 : FontWeight.w400,
            color: ativo ? CoresApp.primaria : CoresApp.sobreSuperficieVariante,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((estados) {
          final ativo = estados.contains(WidgetState.selected);
          return IconThemeData(
            color: ativo ? CoresApp.primaria : CoresApp.sobreSuperficieVariante,
          );
        }),
      ),
    );
  }

  /// Mescla o ThemeData gerado pelo Shad com o [claro] do app.
  static ThemeData mesclarMaterial(ThemeData temaShad) {
    final base = claro;
    return temaShad.copyWith(
      colorScheme: base.colorScheme,
      textTheme: base.textTheme,
      primaryTextTheme: base.primaryTextTheme,
      scaffoldBackgroundColor: base.scaffoldBackgroundColor,
      iconTheme: base.iconTheme,
      primaryIconTheme: base.primaryIconTheme,
      extensions: base.extensions.values,
      appBarTheme: base.appBarTheme,
      floatingActionButtonTheme: base.floatingActionButtonTheme,
      filledButtonTheme: base.filledButtonTheme,
      outlinedButtonTheme: base.outlinedButtonTheme,
      textButtonTheme: base.textButtonTheme,
      iconButtonTheme: base.iconButtonTheme,
      cardTheme: base.cardTheme,
      inputDecorationTheme: base.inputDecorationTheme,
      dividerTheme: base.dividerTheme,
      navigationBarTheme: base.navigationBarTheme,
      dialogTheme: base.dialogTheme,
      datePickerTheme: base.datePickerTheme,
    );
  }
}
