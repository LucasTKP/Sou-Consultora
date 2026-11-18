/// Situação de uma parcela, calculada (nunca gravada).
enum StatusParcela {
  pago('Pago'),
  parcial('Parcial'),
  atrasada('Atrasada'),
  aReceber('A receber');

  const StatusParcela(this.rotulo);

  final String rotulo;
}

/// Uma parcela com o que já foi pago, a venda e a cliente (view
/// `resumo_parcelas`). Valores em centavos.
class ResumoParcela {
  const ResumoParcela({
    required this.id,
    required this.vendaId,
    required this.numero,
    required this.valor,
    required this.vencimento,
    required this.vendaCodigo,
    required this.dataVenda,
    required this.vendaTotal,
    required this.qtdParcelas,
    required this.clienteId,
    required this.clienteNome,
    required this.clienteWhatsapp,
    this.valorPago = 0,
    this.qtdPagamentos = 0,
    this.ultimoPagamento,
    this.nomesItens = '',
  });

  final String id;
  final String vendaId;
  final int numero;
  final int valor;
  final DateTime vencimento;
  final int valorPago;
  final int qtdPagamentos;
  final DateTime? ultimoPagamento;
  final int vendaCodigo;
  final DateTime dataVenda;
  final int vendaTotal;
  final int qtdParcelas;
  final String clienteId;
  final String clienteNome;
  final String clienteWhatsapp;

  /// Nomes dos itens da venda separados por " | " (para a busca).
  final String nomesItens;

  /// Quanto ainda falta pagar.
  int get saldo => valor - valorPago < 0 ? 0 : valor - valorPago;

  bool get paga => saldo == 0;

  /// "1 de 2".
  String get textoNumero => '$numero de $qtdParcelas';

  /// Pago → atrasada (vencida com saldo) → parcial → a receber.
  StatusParcela status({required DateTime hoje}) {
    if (paga) return StatusParcela.pago;
    if (_dia(vencimento).isBefore(_dia(hoje))) return StatusParcela.atrasada;
    if (valorPago > 0) return StatusParcela.parcial;
    return StatusParcela.aReceber;
  }

  /// Dias desde o vencimento (0 se ainda não venceu).
  int diasAtraso({required DateTime hoje}) {
    final dias = _dia(hoje).difference(_dia(vencimento)).inDays;
    return dias < 0 ? 0 : dias;
  }

  /// Vencimento hoje e ainda com saldo.
  bool venceHoje({required DateTime hoje}) =>
      !paga && _dia(vencimento) == _dia(hoje);

  /// "Parcela 2/2" ou "Parcela única".
  String get textoCurto =>
      qtdParcelas == 1 ? 'Parcela única' : 'Parcela $numero/$qtdParcelas';

  /// "#0012".
  String get codigoVenda => '#${vendaCodigo.toString().padLeft(4, '0')}';

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);
}
