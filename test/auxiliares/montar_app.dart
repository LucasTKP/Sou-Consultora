// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sou_consultora/ui/temas/tema_app.dart';

/// Mesmo esqueleto do `main.dart` (ShadApp + MaterialApp), com idioma pt-BR.
Widget appDeTeste({Widget? home, RouterConfig<Object>? roteador}) {
  return ShadApp.custom(
    theme: TemaApp.temaShadClaro,
    themeMode: ThemeMode.light,
    appBuilder: (context) {
      const delegados = <LocalizationsDelegate<dynamic>>[
        GlobalShadLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];
      const idiomas = [Locale('pt', 'BR')];
      final tema = TemaApp.mesclarMaterial(Theme.of(context));
      ShadAppBuilder construtor(BuildContext _, Widget? filho) =>
          ShadAppBuilder(child: filho!);

      if (roteador != null) {
        return MaterialApp.router(
          theme: tema,
          locale: idiomas.first,
          supportedLocales: idiomas,
          localizationsDelegates: delegados,
          routerConfig: roteador,
          builder: construtor,
        );
      }
      return MaterialApp(
        theme: tema,
        locale: idiomas.first,
        supportedLocales: idiomas,
        localizationsDelegates: delegados,
        home: home,
        builder: construtor,
      );
    },
  );
}

/// Simula a tela de um celular (390×844) durante o teste.
void usarTelaDeCelular(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Monta um widget isolado numa tela rolável.
Future<void> montar(WidgetTester tester, Widget filho) async {
  await tester.pumpWidget(
    appDeTeste(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: filho,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
