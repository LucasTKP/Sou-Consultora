import 'package:sou_consultora/core/model/filtro_produtos.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';

enum CarregamentoProdutos { carregando, pronto, erro }

class ProdutosListaState {
  const ProdutosListaState({
    this.carregamento = CarregamentoProdutos.carregando,
    this.todos = const [],
    this.marcaCategoria = FiltroMarcaCategoria.todas,
    this.estoque = StatusFiltroEstoque.todos,
    this.busca = '',
    this.ordem = OrdemPreco.maior,
    this.mensagemErro,
  });

  final CarregamentoProdutos carregamento;

  /// Todos os produtos da consultora (sem filtro).
  final List<ResumoProduto> todos;
  final FiltroMarcaCategoria marcaCategoria;
  final StatusFiltroEstoque estoque;
  final String busca;
  final OrdemPreco ordem;
  final String? mensagemErro;

  /// Produtos exibidos, já filtrados, buscados e ordenados.
  List<ResumoProduto> get visiveis => FiltroProdutos.aplicar(
    todos,
    marcaCategoria: marcaCategoria,
    estoque: estoque,
    busca: busca,
    ordem: ordem,
  );

  Map<StatusFiltroEstoque, int> get contagens =>
      FiltroProdutos.contagens(todos);

  List<FiltroMarcaCategoria> get opcoesMarcaCategoria =>
      FiltroProdutos.opcoesMarcaCategoria(todos);

  ProdutosListaState copyWith({
    CarregamentoProdutos? carregamento,
    List<ResumoProduto>? todos,
    FiltroMarcaCategoria? marcaCategoria,
    StatusFiltroEstoque? estoque,
    String? busca,
    OrdemPreco? ordem,
    String? Function()? mensagemErro,
  }) {
    return ProdutosListaState(
      carregamento: carregamento ?? this.carregamento,
      todos: todos ?? this.todos,
      marcaCategoria: marcaCategoria ?? this.marcaCategoria,
      estoque: estoque ?? this.estoque,
      busca: busca ?? this.busca,
      ordem: ordem ?? this.ordem,
      mensagemErro: mensagemErro != null ? mensagemErro() : this.mensagemErro,
    );
  }
}
