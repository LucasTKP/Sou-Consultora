sealed class AtualizacaoState {
  const AtualizacaoState();
}

final class AtualizacaoInicial extends AtualizacaoState {
  const AtualizacaoInicial();
}

final class AtualizacaoAbrindoLoja extends AtualizacaoState {
  const AtualizacaoAbrindoLoja();
}

final class AtualizacaoErro extends AtualizacaoState {
  const AtualizacaoErro(this.mensagem);
  final String mensagem;
}
