import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/model/resumo_servico.dart';

/// Espelho da view `resumo_servicos`.
class ResumoServicoDto {
  const ResumoServicoDto({
    required this.id,
    required this.categoriaId,
    required this.nome,
    required this.precoCobrado,
    required this.createdAt,
    required this.categoriaNome,
    this.custoMateriais,
    this.duracaoMinutos,
    this.observacoes,
    this.fotoUrl,
  });

  factory ResumoServicoDto.fromJson(Map<String, dynamic> json) {
    return ResumoServicoDto(
      id: json['id'] as String,
      categoriaId: json['categoria_id'] as String,
      nome: json['nome'] as String,
      precoCobrado: ConversoresDto.centavos(json['preco_cobrado']),
      custoMateriais: json['custo_materiais'] == null
          ? null
          : ConversoresDto.centavos(json['custo_materiais']),
      duracaoMinutos: json['duracao_minutos'] as int?,
      observacoes: json['observacoes'] as String?,
      fotoUrl: json['foto_url'] as String?,
      createdAt: ConversoresDto.momento(json['created_at'])!,
      categoriaNome: json['categoria_nome'] as String,
    );
  }

  final String id;
  final String categoriaId;
  final String nome;

  /// Centavos.
  final int precoCobrado;
  final int? custoMateriais;
  final int? duracaoMinutos;
  final String? observacoes;

  /// Caminho no bucket `fotos`.
  final String? fotoUrl;
  final DateTime createdAt;
  final String categoriaNome;

  ResumoServico paraModel({String? urlFoto}) => ResumoServico(
    id: id,
    nome: nome,
    categoriaId: categoriaId,
    categoriaNome: categoriaNome,
    precoCobrado: precoCobrado,
    custoMateriais: custoMateriais,
    duracaoMinutos: duracaoMinutos,
    observacoes: observacoes,
    caminhoFoto: fotoUrl,
    urlFoto: urlFoto,
    criadoEm: createdAt,
  );
}
