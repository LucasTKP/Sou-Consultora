import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/model/venda.dart';

/// Espelho da view `resumo_vendas`.
class ResumoVendaDto {
  const ResumoVendaDto({
    required this.id,
    required this.codigo,
    required this.clienteId,
    required this.clienteNome,
    required this.clienteWhatsapp,
    required this.dataVenda,
    required this.subtotal,
    required this.totalDescontos,
    required this.total,
    required this.qtdItens,
    required this.qtdUnidades,
    required this.nomesItens,
    required this.qtdParcelas,
    required this.qtdParcelasPagas,
    required this.valorPago,
    required this.saldo,
    required this.valorAtrasado,
    required this.temPagamento,
    this.observacoes,
    this.primeiroItem,
    this.proximoVencimento,
  });

  factory ResumoVendaDto.fromJson(Map<String, dynamic> json) {
    return ResumoVendaDto(
      id: json['id'] as String,
      codigo: json['codigo'] as int,
      clienteId: json['cliente_id'] as String,
      clienteNome: json['cliente_nome'] as String,
      clienteWhatsapp: json['cliente_whatsapp'] as String,
      dataVenda: ConversoresDto.momento(json['data_venda'])!,
      subtotal: ConversoresDto.centavos(json['subtotal']),
      totalDescontos: ConversoresDto.centavos(json['total_descontos']),
      total: ConversoresDto.centavos(json['total']),
      observacoes: json['observacoes'] as String?,
      qtdItens: json['qtd_itens'] as int,
      qtdUnidades: json['qtd_unidades'] as int,
      nomesItens: json['nomes_itens'] as String,
      primeiroItem: json['primeiro_item'] as String?,
      qtdParcelas: json['qtd_parcelas'] as int,
      qtdParcelasPagas: json['qtd_parcelas_pagas'] as int,
      valorPago: ConversoresDto.centavos(json['valor_pago']),
      saldo: ConversoresDto.centavos(json['saldo']),
      valorAtrasado: ConversoresDto.centavos(json['valor_atrasado']),
      proximoVencimento: ConversoresDto.data(json['proximo_vencimento']),
      temPagamento: json['tem_pagamento'] as bool,
    );
  }

  final String id;
  final int codigo;
  final String clienteId;
  final String clienteNome;
  final String clienteWhatsapp;
  final DateTime dataVenda;

  /// Valores em centavos.
  final int subtotal;
  final int totalDescontos;
  final int total;
  final String? observacoes;
  final int qtdItens;
  final int qtdUnidades;
  final String nomesItens;
  final String? primeiroItem;
  final int qtdParcelas;
  final int qtdParcelasPagas;
  final int valorPago;
  final int saldo;
  final int valorAtrasado;
  final DateTime? proximoVencimento;
  final bool temPagamento;

  ResumoVenda paraModel() => ResumoVenda(
    id: id,
    codigo: codigo,
    clienteId: clienteId,
    clienteNome: clienteNome,
    clienteWhatsapp: clienteWhatsapp,
    dataVenda: dataVenda,
    subtotal: subtotal,
    totalDescontos: totalDescontos,
    total: total,
    observacoes: observacoes,
    qtdItens: qtdItens,
    qtdUnidades: qtdUnidades,
    nomesItens: nomesItens,
    primeiroItem: primeiroItem,
    qtdParcelas: qtdParcelas,
    qtdParcelasPagas: qtdParcelasPagas,
    valorPago: valorPago,
    saldo: saldo,
    valorAtrasado: valorAtrasado,
    proximoVencimento: proximoVencimento,
    temPagamento: temPagamento,
  );
}
