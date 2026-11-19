/// Produto do catálogo das marcas (vira ponto de partida de um produto da consultora).
class ProdutoCatalogo {
  const ProdutoCatalogo({
    required this.id,
    required this.marca,
    required this.codigo,
    required this.nome,
    this.categoria,
    this.caminhoFoto,
    this.urlFoto,
  });

  final String id;

  /// Nome da marca = nome do fornecedor da consultora (ex.: "Natura").
  final String marca;

  /// Código da revista.
  final String codigo;
  final String nome;

  /// Nome da categoria padrão sugerida (ex.: "Maquiagem").
  final String? categoria;
  final String? caminhoFoto;

  /// URL assinada, temporária, só para exibir a miniatura.
  final String? urlFoto;
}
