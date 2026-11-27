import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/model/forma_pagamento.dart';
import 'package:sou_consultora/core/model/pagamento.dart';

/// Espelho da view `pagamentos_parcelas`.
class PagamentoDto {
  const PagamentoDto({
    required this.id,
    required this.parcelaId,
    required this.vendaId,
    required this.valor,
    required this.formaPagamento,
    required this.dataPagamento,
    this.observacao,
  });

  factory PagamentoDto.fromJson(Map<String, dynamic> json) {
    return PagamentoDto(
      id: json['id'] as String,
      parcelaId: json['parcela_id'] as String,
      vendaId: json['venda_id'] as String,
      valor: ConversoresDto.centavos(json['valor']),
      formaPagamento: json['forma_pagamento'] as String,
      dataPagamento: ConversoresDto.momento(json['data_pagamento'])!,
      observacao: json['observacao'] as String?,
    );
  }

  final String id;
  final String parcelaId;
  final String vendaId;

  /// Centavos.
  final int valor;

  /// `pix`, `cartao` ou `dinheiro`.
  final String formaPagamento;
  final DateTime dataPagamento;
  final String? observacao;

  Pagamento paraModel() => Pagamento(
    id: id,
    parcelaId: parcelaId,
    vendaId: vendaId,
    valor: valor,
    forma: FormaPagamento.doBanco(formaPagamento),
    data: dataPagamento,
    observacao: observacao,
  );
}
