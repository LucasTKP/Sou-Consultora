sealed class FalhaApp {
  const FalhaApp(this.mensagem);

  final String mensagem;
}

final class FalhaAutenticacao extends FalhaApp {
  const FalhaAutenticacao(super.mensagem);
}

final class FalhaRede extends FalhaApp {
  const FalhaRede(super.mensagem);
}

final class FalhaInesperada extends FalhaApp {
  const FalhaInesperada(super.mensagem);
}
