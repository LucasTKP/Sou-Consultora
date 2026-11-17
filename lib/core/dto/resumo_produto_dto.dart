import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';

/// Espelho da view `resumo_produtos`.
class ResumoProdutoDto {
  const ResumoProdutoDto({
    required this.id,
    required this.fornecedorId,
    required this.categoriaId,
    required this.nome,
    required this.precoVenda,
    required this.createdAt,
    required this.fornecedorNome,
    required this.fornecedorAtivo,
    required this.categoriaNome,
    required this.qtdDisponivel,
    this.codigo,
    this.precoCusto,
    this.durabilidadeDias,
    this.observacoes,
    this.fotoUrl,
    this.validadeAtual,
  });

  factory ResumoProdutoDto.fromJson(Map<String, dynamic> json) {
    return ResumoProdutoDto(
      id: json['id'] as String,
      fornecedorId: json['fornecedor_id'] as String,
      categoriaId: json['categoria_id'] as String,
      nome: json['nome'] as String,
      codigo: json['codigo'] as String?,
      precoVenda: ConversoresDto.centavos(json['preco_venda']),
      precoCusto: json['preco_custo'] == null
          ? null
          : ConversoresDto.centavos(json['preco_custo']),
      durabilidadeDias: json['durabilidade_dias'] as int?,
      observacoes: json['observacoes'] as String?,
      fotoUrl: json['foto_url'] as String?,
      createdAt: ConversoresDto.momento(json['created_at'])!,
      fornecedorNome: json['fornecedor_nome'] as String,
      fornecedorAtivo: json['fornecedor_ativo'] as bool,
      categoriaNome: json['categoria_nome'] as String,
      qtdDisponivel: json['qtd_disponivel'] as int,
      validadeAtual: ConversoresDto.data(json['validade_atual']),
    );
  }

  final String id;
  final String fornecedorId;
  final String categoriaId;
  final String nome;
  final String? codigo;

  /// Valores em centavos.
  final int precoVenda;
  final int? precoCusto;
  final int? durabilidadeDias;
  final String? observacoes;

  /// Caminho no bucket `fotos`.
  final String? fotoUrl;
  final DateTime createdAt;
  final String fornecedorNome;
  final bool fornecedorAtivo;
  final String categoriaNome;
  final int qtdDisponivel;
  final DateTime? validadeAtual;

  ResumoProduto paraModel({String? urlFoto}) {
    return ResumoProduto(
      id: id,
      nome: nome,
      fornecedorId: fornecedorId,
      fornecedorNome: fornecedorNome,
      fornecedorAtivo: fornecedorAtivo,
      categoriaId: categoriaId,
      categoriaNome: categoriaNome,
      codigo: codigo,
      precoVenda: precoVenda,
      precoCusto: precoCusto,
      durabilidadeDias: durabilidadeDias,
      observacoes: observacoes,
      caminhoFoto: fotoUrl,
      urlFoto: urlFoto,
      criadoEm: createdAt,
      qtdDisponivel: qtdDisponivel,
      validadeAtual: validadeAtual,
    );
  }
}
