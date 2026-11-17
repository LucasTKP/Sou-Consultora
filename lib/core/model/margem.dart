/// Faixa da margem prevista, pela porcentagem sobre o preço de venda.
enum FaixaMargem {
  excelente('Excelente'),
  boa('Boa'),
  baixa('Baixa'),
  prejuizo('Prejuízo');

  const FaixaMargem(this.rotulo);

  final String rotulo;
}

/// Margem de um item: preço de venda − custo, em centavos e em % da venda.
class Margem {
  const Margem._(this.valor, this.porcentagem, this.faixa);

  /// Excelente a partir de 25%; boa a partir de 10%; baixa até 0%;
  /// prejuízo quando o custo passa do preço de venda.
  factory Margem.calcular({required int precoVenda, required int custo}) {
    final valor = precoVenda - custo;
    final porcentagem = precoVenda <= 0 ? 0.0 : valor * 100 / precoVenda;
    return Margem._(valor, porcentagem, _faixa(valor, precoVenda));
  }

  /// Em centavos (negativo = prejuízo).
  final int valor;

  /// Ex.: 29.5 para 29,5%.
  final double porcentagem;
  final FaixaMargem faixa;

  // Comparação em inteiros para não errar a fronteira por arredondamento.
  static FaixaMargem _faixa(int valor, int precoVenda) {
    if (valor < 0) return FaixaMargem.prejuizo;
    if (valor * 100 >= precoVenda * 25) return FaixaMargem.excelente;
    if (valor * 100 >= precoVenda * 10) return FaixaMargem.boa;
    return FaixaMargem.baixa;
  }
}
