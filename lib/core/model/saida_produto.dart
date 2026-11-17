/// Uma venda que consumiu o produto do estoque (linha da view `saidas_produtos`).
class SaidaProduto {
  const SaidaProduto({
    required this.itemVendaId,
    required this.vendaId,
    required this.dataVenda,
    required this.clienteNome,
    required this.quantidade,
    required this.valor,
  });

  final String itemVendaId;
  final String vendaId;
  final DateTime dataVenda;
  final String clienteNome;
  final int quantidade;

  /// Valor do item, em centavos.
  final int valor;
}
