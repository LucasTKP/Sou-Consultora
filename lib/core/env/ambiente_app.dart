import 'package:envied/envied.dart';

part 'ambiente_app.g.dart';

/// Variáveis de ambiente do app (geradas via Envied a partir do `.env`).
@Envied(path: '.env', obfuscate: true)
abstract final class AmbienteApp {
  @EnviedField(varName: 'SUPABASE_URL')
  static final String urlSupabase = _AmbienteApp.urlSupabase;

  @EnviedField(varName: 'SUPABASE_ANON_KEY')
  static final String chaveAnonSupabase = _AmbienteApp.chaveAnonSupabase;

  @EnviedField(varName: 'GOOGLE_WEB_CLIENT_ID')
  static final String idClienteGoogleWeb = _AmbienteApp.idClienteGoogleWeb;

  @EnviedField(varName: 'GOOGLE_IOS_CLIENT_ID')
  static final String idClienteGoogleIos = _AmbienteApp.idClienteGoogleIos;
}
