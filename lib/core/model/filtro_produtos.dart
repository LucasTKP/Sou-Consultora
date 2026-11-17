import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/core/model/texto_busca.dart';

/// O que o seletor "Marca / Categoria" filtra.
enum TipoFiltroMarcaCategoria { todas, marca, categoria }

/// Uma opção do seletor "Marca / Categoria": todas, uma marca ou uma categoria.
class FiltroMarcaCategoria {
  const FiltroMarcaCategoria._(this.tipo, this.id, this.rotulo);

  const FiltroMarcaCategoria.marca(String id, String nome)
    : this._(TipoFiltroMarcaCategoria.marca, id, nome);

  const FiltroMarcaCategoria.categoria(String id, String nome)
    : this._(TipoFiltroMarcaCategoria.categoria, id, nome);

  static const todas = FiltroMarcaCategoria._(
    TipoFiltroMarcaCategoria.todas,
    null,
    'Todas as marcas',
  );

  final TipoFiltroMarcaCategoria tipo;
  final String? id;
  final String rotulo;

  bool aceita(ResumoProduto produto) => switch (tipo) {
    TipoFiltroMarcaCategoria.todas => true,
    TipoFiltroMarcaCategoria.marca => produto.fornecedorId == id,
    TipoFiltroMarcaCategoria.categoria => produto.categoriaId == id,
  };

  @override
  bool operator ==(Object other) =>
      other is FiltroMarcaCategoria && other.tipo == tipo && other.id == id;

  @override
  int get hashCode => Object.hash(tipo, id);
}

/// Opções do filtro "Status de estoque".
enum StatusFiltroEstoque {
  todos('Todos'),
  emEstoque('Em estoque'),
  baixo('Baixo'),
  esgotado('Esgotado');

  const StatusFiltroEstoque(this.rotulo);

  final String rotulo;

  bool aceita(ResumoProduto produto) => switch (this) {
    todos => true,
    emEstoque => produto.situacao == SituacaoEstoque.emEstoque,
    baixo => produto.situacao == SituacaoEstoque.baixo,
    esgotado => produto.situacao == SituacaoEstoque.esgotado,
  };
}

/// Ordem da lista pelo preço de venda.
enum OrdemPreco {
  maior('Preço: Maior'),
  menor('Preço: Menor');

  const OrdemPreco(this.rotulo);

  final String rotulo;

  OrdemPreco get invertida => this == maior ? menor : maior;
}

/// Regras de busca, filtro e ordem da lista de produtos (puras, sem Flutter).
abstract final class FiltroProdutos {
  static List<ResumoProduto> aplicar(
    List<ResumoProduto> produtos, {
    required FiltroMarcaCategoria marcaCategoria,
    required StatusFiltroEstoque estoque,
    required String busca,
    required OrdemPreco ordem,
  }) {
    final filtrados =
        produtos
            .where(
              (p) =>
                  marcaCategoria.aceita(p) &&
                  estoque.aceita(p) &&
                  p.combinaBusca(busca),
            )
            .toList()
          ..sort((a, b) {
            final porPreco = ordem == OrdemPreco.maior
                ? b.precoVenda.compareTo(a.precoVenda)
                : a.precoVenda.compareTo(b.precoVenda);
            if (porPreco != 0) return porPreco;
            return TextoBusca.normalizar(a.nome)
                .compareTo(TextoBusca.normalizar(b.nome));
          });
    return filtrados;
  }

  /// Quantidade de produtos em cada opção do filtro de estoque.
  static Map<StatusFiltroEstoque, int> contagens(List<ResumoProduto> produtos) {
    return {
      for (final status in StatusFiltroEstoque.values)
        status: produtos.where(status.aceita).length,
    };
  }

  /// "Todas as marcas", depois as marcas e as categorias que têm produtos,
  /// cada grupo em ordem alfabética.
  static List<FiltroMarcaCategoria> opcoesMarcaCategoria(
    List<ResumoProduto> produtos,
  ) {
    int porNome(FiltroMarcaCategoria a, FiltroMarcaCategoria b) =>
        TextoBusca.normalizar(a.rotulo)
            .compareTo(TextoBusca.normalizar(b.rotulo));
    final marcas = {
      for (final p in produtos)
        FiltroMarcaCategoria.marca(p.fornecedorId, p.fornecedorNome),
    }.toList()..sort(porNome);
    final categorias = {
      for (final p in produtos)
        FiltroMarcaCategoria.categoria(p.categoriaId, p.categoriaNome),
    }.toList()..sort(porNome);
    return [FiltroMarcaCategoria.todas, ...marcas, ...categorias];
  }
}
