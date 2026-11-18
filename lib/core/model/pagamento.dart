import 'package:sou_consultora/core/model/forma_pagamento.dart';

/// Um pagamento de parcela (view `pagamentos_parcelas`). Valor em centavos.
class Pagamento {
  const Pagamento({
    required this.id,
    required this.parcelaId,
    required this.vendaId,
    required this.valor,
    required this.forma,
    required this.data,
    this.observacao,
  });

  final String id;
  final String parcelaId;
  final String vendaId;
  final int valor;
  final FormaPagamento forma;
  final DateTime data;
  final String? observacao;

  /// Valor do pagamento: > 0 e até o [saldo] da parcela.
  static String? validarValor(int? centavos, {required int saldo}) {
    if (centavos == null || centavos <= 0) return 'Informe o valor recebido';
    if (centavos > saldo) return 'O valor não pode passar do saldo da parcela';
    return null;
  }

  static String? validarData(DateTime data, {required DateTime hoje}) {
    final dia = DateTime(data.year, data.month, data.day);
    return dia.isAfter(DateTime(hoje.year, hoje.month, hoje.day))
        ? 'A data do pagamento não pode ser no futuro'
        : null;
  }
}
