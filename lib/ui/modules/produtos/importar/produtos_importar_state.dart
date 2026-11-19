import 'package:sou_consultora/core/model/produto_catalogo.dart';

class ProdutosImportarState {
  const ProdutosImportarState({
    this.carregando = true,
    this.erro,
    this.itens = const [],
    this.marca,
    this.texto = '',
    this.jaCadastrados = const {},
  });

  /// Quantos itens a busca traz no máximo (acima disso, "refine a busca").
  static const limite = 60;

  final bool carregando;
  final String? erro;
  final List<ProdutoCatalogo> itens;

  /// Nome da marca filtrada (null = todas).
  final String? marca;
  final String texto;

  /// Chaves ([ProdutoCatalogo.chave]) dos produtos que a consultora já cadastrou.
  final Set<String> jaCadastrados;

  bool jaTem(ProdutoCatalogo produto) => jaCadastrados.contains(produto.chave);

  bool get possivelTerMais => itens.length >= limite;

  ProdutosImportarState copyWith({
    bool? carregando,
    String? Function()? erro,
    List<ProdutoCatalogo>? itens,
    String? Function()? marca,
    String? texto,
    Set<String>? jaCadastrados,
  }) {
    return ProdutosImportarState(
      carregando: carregando ?? this.carregando,
      erro: erro != null ? erro() : this.erro,
      itens: itens ?? this.itens,
      marca: marca != null ? marca() : this.marca,
      texto: texto ?? this.texto,
      jaCadastrados: jaCadastrados ?? this.jaCadastrados,
    );
  }
}
