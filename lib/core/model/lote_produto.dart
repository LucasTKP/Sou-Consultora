/// Situação de um lote: nada saiu, parte saiu ou acabou.
enum SituacaoLote { recebido, restante, esgotado }

/// Um lote de estoque do produto (linha da view `lotes_produtos`).
/// Valores em centavos.
class LoteProduto {
  const LoteProduto({
    required this.id,
    required this.produtoId,
    required this.numero,
    required this.quantidade,
    required this.disponivel,
    required this.custoUnitario,
    required this.dataCompra,
    required this.fornecedorNome,
    this.validade,
    this.qtdSaidas = 0,
  });

  final String id;
  final String produtoId;
  final int numero;

  /// Unidades recebidas.
  final int quantidade;

  /// Unidades que ainda restam.
  final int disponivel;
  final int custoUnitario;
  final DateTime dataCompra;
  final String fornecedorNome;
  final DateTime? validade;

  /// Unidades que já saíram em vendas.
  final int qtdSaidas;

  /// "#01", "#02"...
  String get rotulo => '#${numero.toString().padLeft(2, '0')}';

  int get totalPago => quantidade * custoUnitario;

  int get vendidas => quantidade - disponivel;

  SituacaoLote get situacao {
    if (disponivel <= 0) return SituacaoLote.esgotado;
    if (disponivel == quantidade) return SituacaoLote.recebido;
    return SituacaoLote.restante;
  }

  /// "3 un recebidas", "1 un restante", "Esgotado".
  String get textoSituacao => switch (situacao) {
    SituacaoLote.recebido =>
      '$quantidade un ${_plural(quantidade, 'recebida')}',
    SituacaoLote.restante =>
      '$disponivel un ${_plural(disponivel, 'restante')}',
    SituacaoLote.esgotado => 'Esgotado',
  };

  /// "3 disponíveis" ou "1 de 2 vendida".
  String get textoSaldo => situacao == SituacaoLote.recebido
      ? '$disponivel ${disponivel == 1 ? 'disponível' : 'disponíveis'}'
      : '$vendidas de $quantidade ${_plural(vendidas, 'vendida')}';

  /// Só lote que nunca teve saída pode ser apagado.
  bool get podeApagar => disponivel == quantidade && qtdSaidas == 0;

  static String _plural(int quantidade, String palavra) =>
      quantidade == 1 ? palavra : '${palavra}s';
}
