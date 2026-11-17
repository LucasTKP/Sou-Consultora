import 'package:get_it/get_it.dart';
import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/service/servico_consultora.dart';
import 'package:sou_consultora/core/service/servico_foto_dispositivo.dart';
import 'package:sou_consultora/core/service/servico_autenticacao.dart';

final GetIt injetor = GetIt.instance;

/// Registra as dependências compartilhadas do app.
void configurarDependencias() {
  if (!injetor.isRegistered<ApiSupabase>()) {
    injetor.registerLazySingleton<ApiSupabase>(ApiSupabase.new);
  }

  if (!injetor.isRegistered<ServicoAutenticacao>()) {
    injetor.registerLazySingleton<ServicoAutenticacao>(() => ServicoAutenticacao(api: injetor()));
  }

  if (!injetor.isRegistered<RepositorioAutenticacao>()) {
    injetor.registerLazySingleton<RepositorioAutenticacao>(() => RepositorioAutenticacao(servico: injetor()));
  }

  if (!injetor.isRegistered<ServicoConsultora>()) {
    injetor.registerLazySingleton<ServicoConsultora>(() => ServicoConsultora(api: injetor()));
  }

  if (!injetor.isRegistered<ServicoFotoDispositivo>()) {
    injetor.registerLazySingleton<ServicoFotoDispositivo>(ServicoFotoDispositivoNativo.new);
  }

  if (!injetor.isRegistered<RepositorioConsultora>()) {
    injetor.registerLazySingleton<RepositorioConsultora>(
      () => RepositorioConsultora(servico: injetor(), fotos: injetor()),
    );
  }
}
