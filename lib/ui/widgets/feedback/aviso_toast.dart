/// Tipo visual de um aviso temporário.
enum TipoToast { erro, aviso, sucesso }

/// Mensagem que a tela mostra no toast.
class AvisoToast {
  const AvisoToast.erro(this.mensagem) : tipo = TipoToast.erro;

  const AvisoToast.aviso(this.mensagem) : tipo = TipoToast.aviso;

  const AvisoToast.sucesso(this.mensagem) : tipo = TipoToast.sucesso;

  final String mensagem;
  final TipoToast tipo;

  @override
  bool operator ==(Object other) =>
      other is AvisoToast && other.mensagem == mensagem && other.tipo == tipo;

  @override
  int get hashCode => Object.hash(mensagem, tipo);
}
