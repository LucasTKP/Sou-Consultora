import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/model/lembrete_recompra.dart';

/// Espelho da view `lembretes_recompra`.
class LembreteRecompraDto {
  const LembreteRecompraDto({
    required this.clienteId,
    required this.clienteNome,
    required this.clienteWhatsapp,
    required this.produtoId,
    required this.produtoNome,
    required this.durabilidadeDias,
    required this.ultimaCompra,
  });

  factory LembreteRecompraDto.fromJson(Map<String, dynamic> json) {
    return LembreteRecompraDto(
      clienteId: json['cliente_id'] as String,
      clienteNome: json['cliente_nome'] as String,
      clienteWhatsapp: json['cliente_whatsapp'] as String,
      produtoId: json['produto_id'] as String,
      produtoNome: json['produto_nome'] as String,
      durabilidadeDias: json['durabilidade_dias'] as int,
      ultimaCompra: ConversoresDto.data(json['ultima_compra'])!,
    );
  }

  final String clienteId;
  final String clienteNome;
  final String clienteWhatsapp;
  final String produtoId;
  final String produtoNome;

  /// 30 a 180 (a view só traz produtos com duração prevista).
  final int durabilidadeDias;

  /// `date` (dia em São Paulo).
  final DateTime ultimaCompra;

  LembreteRecompra paraModel() => LembreteRecompra(
    clienteId: clienteId,
    clienteNome: clienteNome,
    clienteWhatsapp: clienteWhatsapp,
    produtoId: produtoId,
    produtoNome: produtoNome,
    durabilidadeDias: durabilidadeDias,
    ultimaCompra: ultimaCompra,
  );
}
