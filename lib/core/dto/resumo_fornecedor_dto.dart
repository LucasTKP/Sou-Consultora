import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';

/// Espelho da view `resumo_fornecedores`.
class ResumoFornecedorDto {
  const ResumoFornecedorDto({
    required this.id,
    required this.nome,
    required this.ativo,
    required this.createdAt,
    required this.qtdEmAberto,
    required this.valorEmAberto,
    required this.qtdAtrasados,
    required this.valorAtrasado,
    required this.qtdVenceHoje,
    required this.qtdPagos,
    required this.valorPagos,
    this.ramo,
    this.contato,
    this.telefone,
    this.observacoes,
  });

  factory ResumoFornecedorDto.fromJson(Map<String, dynamic> json) {
    return ResumoFornecedorDto(
      id: json['id'] as String,
      nome: json['nome'] as String,
      ramo: json['ramo'] as String?,
      contato: json['contato'] as String?,
      telefone: json['telefone'] as String?,
      observacoes: json['observacoes'] as String?,
      ativo: json['ativo'] as bool,
      createdAt: ConversoresDto.momento(json['created_at'])!,
      qtdEmAberto: json['qtd_em_aberto'] as int,
      valorEmAberto: ConversoresDto.centavos(json['valor_em_aberto']),
      qtdAtrasados: json['qtd_atrasados'] as int,
      valorAtrasado: ConversoresDto.centavos(json['valor_atrasado']),
      qtdVenceHoje: json['qtd_vence_hoje'] as int,
      qtdPagos: json['qtd_pagos'] as int,
      valorPagos: ConversoresDto.centavos(json['valor_pagos']),
    );
  }

  final String id;
  final String nome;
  final String? ramo;
  final String? contato;
  final String? telefone;
  final String? observacoes;
  final bool ativo;
  final DateTime createdAt;
  final int qtdEmAberto;

  /// Valores em centavos.
  final int valorEmAberto;
  final int qtdAtrasados;
  final int valorAtrasado;
  final int qtdVenceHoje;
  final int qtdPagos;
  final int valorPagos;

  ResumoFornecedor paraModel() {
    return ResumoFornecedor(
      id: id,
      nome: nome,
      criadoEm: createdAt,
      ramo: ramo,
      contato: contato,
      telefone: telefone,
      observacoes: observacoes,
      ativo: ativo,
      qtdEmAberto: qtdEmAberto,
      valorEmAberto: valorEmAberto,
      qtdAtrasados: qtdAtrasados,
      valorAtrasado: valorAtrasado,
      qtdVenceHoje: qtdVenceHoje,
      qtdPagos: qtdPagos,
      valorPagos: valorPagos,
    );
  }
}
