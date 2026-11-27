import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/api/registro_depuracao.dart';

/// Imprime no terminal de depuração as exceções lançadas dentro de cubits.
class ObservadorCubits extends BlocObserver {
  const ObservadorCubits();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    RegistroDepuracao.erro(
      'Exceção em ${bloc.runtimeType}',
      causa: error,
      pilha: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}
