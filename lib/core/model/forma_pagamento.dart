/// Como a cliente pagou (coluna `pagamentos_parcela.forma_pagamento`).
enum FormaPagamento {
  pix('pix', 'Pix'),
  cartao('cartao', 'Cartão'),
  dinheiro('dinheiro', 'Dinheiro');

  const FormaPagamento(this.valorBanco, this.rotulo);

  final String valorBanco;
  final String rotulo;

  static FormaPagamento doBanco(String valor) =>
      values.firstWhere((f) => f.valorBanco == valor, orElse: () => pix);
}
