// ignore_for_file: deprecated_member_use
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/api/cliente_http_com_registro.dart';
import 'package:sou_consultora/core/api/observador_cubits.dart';
import 'package:sou_consultora/core/api/registro_depuracao.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/env/ambiente_app.dart';
import 'package:sou_consultora/ui/navegacao/notificador_acesso.dart';
import 'package:sou_consultora/ui/navegacao/roteador_app.dart';
import 'package:sou_consultora/ui/temas/tema_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';
import 'package:toastification/toastification.dart';
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
  _registrarErrosNaoTratados();
  await Supabase.initialize(
    url: AmbienteApp.urlSupabase,
    anonKey: AmbienteApp.chaveAnonSupabase,
    // Em debug, imprime cada requisição/resposta (auth, banco e storage).
    httpClient: RegistroDepuracao.ativo ? ClienteHttpComRegistro() : null,
  );
  configurarDependencias();
  _inicializado = true;
}

/// Exceções que escapam de cubits e de código assíncrono também vão para o
/// terminal (erros de widget o Flutter já imprime sozinho em debug).
void _registrarErrosNaoTratados() {
  if (!RegistroDepuracao.ativo) return;
  Bloc.observer = const ObservadorCubits();
  PlatformDispatcher.instance.onError = (erro, pilha) {
    RegistroDepuracao.erro('Exceção não tratada', causa: erro, pilha: pilha);
    return true;
  };
}

class MeuApp extends StatefulWidget {
  const MeuApp({super.key});

  @override
  State<MeuApp> createState() => _MeuAppState();
}

class _MeuAppState extends State<MeuApp> {
  late final _acesso = NotificadorAcesso(
    autenticacao: injetor(),
    consultoras: injetor(),
  );
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
            return ToastificationConfigProvider(
              config: ToastApp.configuracao(context),
              child: ShadAppBuilder(child: child!),
            );
          },
          routerConfig: _roteador,
        );
      },
    );
  }
}
