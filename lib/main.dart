// ignore_for_file: deprecated_member_use
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/env/ambiente_app.dart';
import 'package:sou_consultora/ui/navegacao/notificador_acesso.dart';
import 'package:sou_consultora/ui/navegacao/roteador_app.dart';
import 'package:sou_consultora/ui/temas/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await inicializarApp();
  runApp(const MeuApp());
}

var _inicializado = false;

/// Prepara idioma, Supabase e dependências. Pode ser chamado mais de uma vez
/// (os testes E2E sobem o app várias vezes no mesmo processo).
Future<void> inicializarApp() async {
  if (_inicializado) return;
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  await Supabase.initialize(url: AmbienteApp.urlSupabase, anonKey: AmbienteApp.chaveAnonSupabase);
  configurarDependencias();
  _inicializado = true;
}

class MeuApp extends StatefulWidget {
  const MeuApp({super.key});

  @override
  State<MeuApp> createState() => _MeuAppState();
}

class _MeuAppState extends State<MeuApp> {
  late final _acesso = NotificadorAcesso(autenticacao: injetor(), consultoras: injetor());
  late final _roteador = RoteadorApp.criar(acesso: _acesso);

  @override
  void dispose() {
    _roteador.dispose();
    _acesso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadApp.custom(
      theme: TemaApp.temaShadClaro,
      themeMode: ThemeMode.light,
      appBuilder: (context) {
        return MaterialApp.router(
          title: 'Sou Consultora',
          debugShowCheckedModeBanner: false,
          theme: TemaApp.mesclarMaterial(Theme.of(context)),
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
          builder: (context, child) {
            return ShadAppBuilder(child: child!);
          },
          routerConfig: _roteador,
        );
      },
    );
  }
}
