import 'package:sou_consultora/core/model/produto_catalogo.dart';

class ProdutosImportarState {
  const ProdutosImportarState({
    this.carregando = true,
    this.erro,
    this.itens = const [],
    this.marca,
    this.texto = '',
  });

  /// Quantos itens a busca traz no máximo (acima disso, "refine a busca").
  static const limite = 60;

  final bool carregando;
  final String? erro;
  final List<ProdutoCatalogo> itens;

  /// Nome da marca filtrada (null = todas).
  final String? marca;
  final String texto;

  bool get possivelTerMais => itens.length >= limite;

  ProdutosImportarState copyWith({
    bool? carregando,
    String? Function()? erro,
    List<ProdutoCatalogo>? itens,
    String? Function()? marca,
    String? texto,
  }) {
    return ProdutosImportarState(
      carregando: carregando ?? this.carregando,
      erro: erro != null ? erro() : this.erro,
      itens: itens ?? this.itens,
      marca: marca != null ? marca() : this.marca,
      texto: texto ?? this.texto,
    );
  }
}
