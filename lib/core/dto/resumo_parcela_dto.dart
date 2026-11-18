import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/model/parcela.dart';

/// Espelho da view `resumo_parcelas`.
class ResumoParcelaDto {
  const ResumoParcelaDto({
    required this.id,
    required this.vendaId,
    required this.numeroParcela,
    required this.valor,
    required this.dataVencimento,
    required this.valorPago,
    required this.qtdPagamentos,
    required this.vendaCodigo,
    required this.dataVenda,
    required this.vendaTotal,
    required this.qtdParcelas,
    required this.clienteId,
    required this.clienteNome,
    required this.clienteWhatsapp,
    required this.nomesItens,
    this.ultimoPagamento,
  });

  factory ResumoParcelaDto.fromJson(Map<String, dynamic> json) {
    return ResumoParcelaDto(
      id: json['id'] as String,
      vendaId: json['venda_id'] as String,
      numeroParcela: json['numero_parcela'] as int,
      valor: ConversoresDto.centavos(json['valor']),
      dataVencimento: ConversoresDto.data(json['data_vencimento'])!,
      valorPago: ConversoresDto.centavos(json['valor_pago']),
      qtdPagamentos: json['qtd_pagamentos'] as int,
      ultimoPagamento: ConversoresDto.momento(json['ultimo_pagamento']),
      vendaCodigo: json['venda_codigo'] as int,
      dataVenda: ConversoresDto.momento(json['data_venda'])!,
      vendaTotal: ConversoresDto.centavos(json['venda_total']),
      qtdParcelas: json['qtd_parcelas'] as int,
      clienteId: json['cliente_id'] as String,
      clienteNome: json['cliente_nome'] as String,
      clienteWhatsapp: json['cliente_whatsapp'] as String,
      nomesItens: json['nomes_itens'] as String,
    );
  }

  final String id;
  final String vendaId;
  final int numeroParcela;

  /// Centavos.
  final int valor;
  final DateTime dataVencimento;
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

  /// Nomes dos itens da venda separados por " | " (`''` sem itens).
  final String nomesItens;

  ResumoParcela paraModel() => ResumoParcela(
    id: id,
    vendaId: vendaId,
    numero: numeroParcela,
    valor: valor,
    vencimento: dataVencimento,
    valorPago: valorPago,
    qtdPagamentos: qtdPagamentos,
    ultimoPagamento: ultimoPagamento,
    vendaCodigo: vendaCodigo,
    dataVenda: dataVenda,
    vendaTotal: vendaTotal,
    qtdParcelas: qtdParcelas,
    clienteId: clienteId,
    clienteNome: clienteNome,
    clienteWhatsapp: clienteWhatsapp,
    nomesItens: nomesItens,
  );
}
