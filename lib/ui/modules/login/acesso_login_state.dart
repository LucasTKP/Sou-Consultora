sealed class AcessoLoginState {
  const AcessoLoginState();
}

final class AcessoLoginInicial extends AcessoLoginState {
  const AcessoLoginInicial();
}

final class AcessoLoginCarregandoGoogle extends AcessoLoginState {
  const AcessoLoginCarregandoGoogle();
}

final class AcessoLoginCarregandoApple extends AcessoLoginState {
  const AcessoLoginCarregandoApple();
}

final class AcessoLoginErro extends AcessoLoginState {
  const AcessoLoginErro(this.mensagem);
  final String mensagem;
}

final class AcessoLoginSucesso extends AcessoLoginState {
  const AcessoLoginSucesso();
}
