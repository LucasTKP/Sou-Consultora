import 'package:sou_consultora/core/model/chave_pix.dart';
import 'package:sou_consultora/core/model/consultora.dart';

/// Espelho da tabela `consultoras`.
class ConsultoraDto {
  const ConsultoraDto({
    required this.id,
    required this.nome,
    required this.whatsapp,
    required this.ultimoCodigoVenda,
    required this.createdAt,
    this.fotoUrl,
    this.chavePix,
    this.tipoChavePix,
  });

  factory ConsultoraDto.fromJson(Map<String, dynamic> json) {
    return ConsultoraDto(
      id: json['id'] as String,
      nome: json['nome'] as String,
      whatsapp: json['whatsapp'] as String,
      fotoUrl: json['foto_url'] as String?,
      chavePix: json['chave_pix'] as String?,
      tipoChavePix: json['tipo_chave_pix'] as String?,
      ultimoCodigoVenda: json['ultimo_codigo_venda'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String nome;
  final String whatsapp;

  /// Caminho da foto no Storage (não é URL pública).
  final String? fotoUrl;
  final String? chavePix;
  final String? tipoChavePix;
  final int ultimoCodigoVenda;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'whatsapp': whatsapp,
    'foto_url': fotoUrl,
    'chave_pix': chavePix,
    'tipo_chave_pix': tipoChavePix,
    'ultimo_codigo_venda': ultimoCodigoVenda,
    'created_at': createdAt.toIso8601String(),
  };

  Consultora paraModel({String? urlFoto}) {
    final tipo = TipoChavePix.doBanco(tipoChavePix);
    return Consultora(
      id: id,
      nome: nome,
      whatsapp: whatsapp,
      chavePix: tipo == null || chavePix == null
          ? null
          : ChavePix(tipo: tipo, valor: chavePix!),
      caminhoFoto: fotoUrl,
      urlFoto: urlFoto,
    );
  }
}
