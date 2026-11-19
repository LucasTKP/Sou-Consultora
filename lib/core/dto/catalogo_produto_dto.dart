import 'package:sou_consultora/core/model/produto_catalogo.dart';

/// Espelho da tabela `catalogo_produtos`.
class CatalogoProdutoDto {
  const CatalogoProdutoDto({
    required this.id,
    required this.marca,
    required this.codigo,
    required this.nome,
    this.categoria,
    this.fotoCaminho,
  });

  factory CatalogoProdutoDto.fromJson(Map<String, dynamic> json) {
    return CatalogoProdutoDto(
      id: json['id'] as String,
      marca: json['marca'] as String,
      codigo: json['codigo'] as String,
      nome: json['nome'] as String,
      categoria: json['categoria'] as String?,
      fotoCaminho: json['foto_caminho'] as String?,
    );
  }

  final String id;
  final String marca;
  final String codigo;
  final String nome;
  final String? categoria;

  /// Caminho no bucket `catalogo`.
  final String? fotoCaminho;

  ProdutoCatalogo paraModel({String? urlFoto}) => ProdutoCatalogo(
    id: id,
    marca: marca,
    codigo: codigo,
    nome: nome,
    categoria: categoria,
    caminhoFoto: fotoCaminho,
    urlFoto: urlFoto,
  );
}
