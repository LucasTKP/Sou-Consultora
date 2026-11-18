/// Como a consultora pretende pagar o boleto (coluna `boletos.forma_pagamento`).
enum FormaPagamentoBoleto {
  pix('pix', 'Pix'),
  boleto('boleto', 'Boleto'),
  transferencia('transferencia', 'Transferência');

  const FormaPagamentoBoleto(this.valorBanco, this.rotulo);

  final String valorBanco;
  final String rotulo;

  static FormaPagamentoBoleto? doBanco(String? valor) {
    for (final forma in values) {
      if (forma.valorBanco == valor) return forma;
    }
    return null;
  }
}
