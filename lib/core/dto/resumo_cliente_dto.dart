import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/model/resumo_cliente.dart';

/// Espelho da view `resumo_clientes`.
class ResumoClienteDto {
  const ResumoClienteDto({
    required this.id,
    required this.nome,
    required this.whatsapp,
    required this.createdAt,
    required this.qtdCompras,
    required this.totalCompras,
    required this.saldoDevedor,
    required this.valorAtrasado,
    required this.valorVenceHoje,
    this.dataNascimento,
    this.ultimaCompra,
  });

  factory ResumoClienteDto.fromJson(Map<String, dynamic> json) {
    return ResumoClienteDto(
      id: json['id'] as String,
      nome: json['nome'] as String,
      whatsapp: json['whatsapp'] as String,
      dataNascimento: ConversoresDto.data(json['data_nascimento']),
      createdAt: ConversoresDto.momento(json['created_at'])!,
      qtdCompras: json['qtd_compras'] as int,
      totalCompras: ConversoresDto.centavos(json['total_compras']),
      ultimaCompra: ConversoresDto.momento(json['ultima_compra']),
      saldoDevedor: ConversoresDto.centavos(json['saldo_devedor']),
      valorAtrasado: ConversoresDto.centavos(json['valor_atrasado']),
      valorVenceHoje: ConversoresDto.centavos(json['valor_vence_hoje']),
    );
  }

  final String id;
  final String nome;
  final String whatsapp;
  final DateTime? dataNascimento;
  final DateTime createdAt;
  final int qtdCompras;

  /// Valores em centavos.
  final int totalCompras;
  final DateTime? ultimaCompra;
  final int saldoDevedor;
  final int valorAtrasado;
  final int valorVenceHoje;

  ResumoCliente paraModel() {
    return ResumoCliente(
      id: id,
      nome: nome,
      whatsapp: whatsapp,
      criadaEm: createdAt,
      dataNascimento: dataNascimento,
      qtdCompras: qtdCompras,
      totalCompras: totalCompras,
      ultimaCompra: ultimaCompra,
      saldoDevedor: saldoDevedor,
      valorAtrasado: valorAtrasado,
      valorVenceHoje: valorVenceHoje,
    );
  }
}
