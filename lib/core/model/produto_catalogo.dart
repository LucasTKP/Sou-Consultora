import 'package:sou_consultora/core/model/texto_busca.dart';

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

  /// Identifica o produto pela marca e pelo código (sem acento nem maiúsculas),
  /// igual à regra de código único do banco: serve para saber se a consultora
  /// já tem este produto.
  String get chave => chaveDeProduto(marca, codigo);

  static String chaveDeProduto(String marca, String codigo) =>
      '${TextoBusca.normalizar(marca)}|${TextoBusca.normalizar(codigo)}';
}
