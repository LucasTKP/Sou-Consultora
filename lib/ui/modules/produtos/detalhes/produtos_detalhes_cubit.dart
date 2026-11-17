import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/core/repository/repositorio_estoque.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/ui/modules/produtos/detalhes/produtos_detalhes_state.dart';

/// Detalhes do produto: mostra o que está em cache e atualiza pela rede.
/// Carrega também os lotes e as saídas da aba Estoque.
class ProdutosDetalhesCubit extends Cubit<ProdutosDetalhesState> {
  ProdutosDetalhesCubit({
    required this.idProduto,
    RepositorioProdutos? repositorio,
    RepositorioEstoque? estoque,
  }) : _repositorio = repositorio ?? injetor<RepositorioProdutos>(),
       _estoque = estoque ?? injetor<RepositorioEstoque>(),
       super(const ProdutosDetalhesState()) {
    final emCache = _repositorio.resumoEmCache(idProduto);
    if (emCache != null) {
      emit(state.copyWith(produto: emCache, carregando: false));
    }
    carregar();
  }

  final String idProduto;
  final RepositorioProdutos _repositorio;
  final RepositorioEstoque _estoque;

  /// Produto e estoque, em paralelo.
  Future<void> carregar() =>
      Future.wait([_carregarProduto(), carregarEstoque()]);

  Future<void> carregarEstoque() async {
    if (state.lotes.isEmpty) {
      emit(state.copyWith(carregandoEstoque: true, erroEstoque: () => null));
    }
    final (lotes, saidas) = await (
      _estoque.lotes(idProduto),
      _estoque.saidas(idProduto),
    ).wait;
    if (isClosed) return;
    switch ((lotes, saidas)) {
      case (Erro(:final falha), _) || (_, Erro(:final falha)):
        emit(
          state.copyWith(
            carregandoEstoque: false,
            erroEstoque: () => falha.mensagem,
          ),
        );
      case (Sucesso(valor: final lotes), Sucesso(valor: final saidas)):
        emit(
          state.copyWith(
            lotes: lotes,
            saidas: saidas,
            carregandoEstoque: false,
            erroEstoque: () => null,
          ),
        );
    }
  }

  void alterarAba(AbaProduto aba) => emit(state.copyWith(aba: aba));

  void alterarSegmento(SegmentoEstoque segmento) =>
      emit(state.copyWith(segmento: segmento));

  Future<void> apagarLote(String loteId) async {
    final resultado = await _estoque.apagarLote(loteId);
    if (isClosed) return;
    if (resultado case Erro(:final falha)) {
      emit(state.copyWith(aviso: () => falha.mensagem));
      return;
    }
    emit(state.copyWith(aviso: () => 'Lote apagado.'));
    await carregar();
  }

  void limparAviso() => emit(state.copyWith(aviso: () => null));

  Future<void> _carregarProduto() async {
    if (state.produto == null) {
      emit(state.copyWith(carregando: true, erro: () => null));
    }
    final resultado = await _repositorio.buscarResumo(idProduto);
    if (isClosed) return;
    switch (resultado) {
      case Sucesso(valor: final ResumoProduto produto):
        emit(
          state.copyWith(produto: produto, carregando: false, erro: () => null),
        );
      case Sucesso(valor: null):
        emit(
          state.copyWith(
            carregando: false,
            erro: () => 'Produto não encontrado.',
          ),
        );
      case Erro(:final falha):
        _aoFalhar(falha.mensagem);
    }
  }

  /// Com o produto já na tela (cache), a falha da atualização vira aviso.
  void _aoFalhar(String mensagem) {
    if (state.produto != null) {
      emit(state.copyWith(aviso: () => mensagem));
      return;
    }
    emit(state.copyWith(carregando: false, erro: () => mensagem));
  }
}
