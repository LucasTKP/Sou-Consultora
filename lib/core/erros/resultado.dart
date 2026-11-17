import 'package:sou_consultora/core/erros/falha_app.dart';

/// Resultado tipado da borda Service/Repository.
sealed class Resultado<T> {
  const Resultado();
}

final class Sucesso<T> extends Resultado<T> {
  const Sucesso(this.valor);

  final T valor;
}

final class Erro<T> extends Resultado<T> {
  const Erro(this.falha);

  final FalhaApp falha;
}
