import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/core/model/forma_pagamento_boleto.dart';

/// Espelho da view `resumo_boletos`.
class BoletoDto {
  const BoletoDto({
    required this.id,
    required this.fornecedorId,
    required this.fornecedorNome,
    required this.fornecedorAtivo,
    required this.valor,
    required this.dataVencimento,
    required this.createdAt,
    this.formaPagamento,
    this.observacoes,
    this.comprovanteUrl,
    this.dataPagamento,
  });

  factory BoletoDto.fromJson(Map<String, dynamic> json) {
    return BoletoDto(
      id: json['id'] as String,
      fornecedorId: json['fornecedor_id'] as String,
      fornecedorNome: json['fornecedor_nome'] as String,
      fornecedorAtivo: json['fornecedor_ativo'] as bool,
      valor: ConversoresDto.centavos(json['valor']),
      dataVencimento: ConversoresDto.data(json['data_vencimento'])!,
      createdAt: ConversoresDto.momento(json['created_at'])!,
      formaPagamento: json['forma_pagamento'] as String?,
      observacoes: json['observacoes'] as String?,
      comprovanteUrl: json['comprovante_url'] as String?,
      dataPagamento: ConversoresDto.data(json['data_pagamento']),
    );
  }

  final String id;
  final String fornecedorId;
  final String fornecedorNome;
  final bool fornecedorAtivo;

  /// Centavos.
  final int valor;
  final DateTime dataVencimento;
  final DateTime createdAt;

  /// `pix`, `boleto` ou `transferencia`.
  final String? formaPagamento;
  final String? observacoes;

  /// Caminho no bucket `comprovantes` (nunca URL).
  final String? comprovanteUrl;
  final DateTime? dataPagamento;

  ResumoBoleto paraModel() => ResumoBoleto(
    id: id,
    fornecedorId: fornecedorId,
    fornecedorNome: fornecedorNome,
    fornecedorAtivo: fornecedorAtivo,
    valor: valor,
    vencimento: dataVencimento,
    forma: FormaPagamentoBoleto.doBanco(formaPagamento),
    observacoes: observacoes,
    caminhoComprovante: comprovanteUrl,
    dataPagamento: dataPagamento,
  );
}
