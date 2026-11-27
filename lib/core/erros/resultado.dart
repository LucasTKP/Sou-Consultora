import 'package:sou_consultora/core/api/registro_depuracao.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';

/// Resultado tipado da borda Service/Repository.
sealed class Resultado<T> {
  const Resultado();
}

final class Sucesso<T> extends Resultado<T> {
  const Sucesso(this.valor);

  final T valor;
}

/// Toda falha que chega à tela passa por aqui, então o terminal de depuração
/// recebe a mensagem, a exceção original ([causa]) e a pilha.
final class Erro<T> extends Resultado<T> {
  Erro(this.falha, {Object? causa, StackTrace? pilha}) {
    RegistroDepuracao.erro(
      '${falha.runtimeType}: ${falha.mensagem}',
      causa: causa,
      pilha: pilha ?? StackTrace.current,
    );
  }

  final FalhaApp falha;
}
