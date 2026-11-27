/// Envio/remoção da foto do perfil.
class FotoPerfilState {
  const FotoPerfilState({
    this.urlFoto,
    this.iniciais = '?',
    this.processando = false,
    this.erro,
  });

  final String? urlFoto;
  final String iniciais;
  final bool processando;

  /// Falha a exibir uma vez (snackbar).
  final String? erro;

  bool get temFoto => urlFoto != null;
}
