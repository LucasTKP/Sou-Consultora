import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/filtro_produtos.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/ui/modules/produtos/lista/produtos_lista_state.dart';

/// Lista de produtos: carrega, acompanha as alterações do repositório e
/// guarda busca, filtros e ordem escolhidos na tela.
class ProdutosListaCubit extends Cubit<ProdutosListaState> {
  ProdutosListaCubit({RepositorioProdutos? repositorio})
    : _repositorio = repositorio ?? injetor<RepositorioProdutos>(),
      super(const ProdutosListaState()) {
    final emCache = _repositorio.lista;
    if (emCache != null) _aoMudarLista(emCache);
    _assinatura = _repositorio.mudancas.listen(_aoMudarLista);
    carregar();
  }

  final RepositorioProdutos _repositorio;
  late final StreamSubscription<List<ResumoProduto>> _assinatura;

  Future<void> carregar() async {
    if (state.carregamento != CarregamentoProdutos.pronto) {
      emit(state.copyWith(carregamento: CarregamentoProdutos.carregando));
    }
    final resultado = await _repositorio.carregar();
    if (isClosed) return;
    // O sucesso chega pelo stream; aqui só trata a falha.
    if (resultado case Erro(:final falha)) _aoFalhar(falha.mensagem);
  }

  void alterarBusca(String busca) => emit(state.copyWith(busca: busca));

  void alterarMarcaCategoria(FiltroMarcaCategoria filtro) =>
      emit(state.copyWith(marcaCategoria: filtro));

  void alterarEstoque(StatusFiltroEstoque estoque) =>
      emit(state.copyWith(estoque: estoque));

  void alterarOrdem(OrdemPreco ordem) => emit(state.copyWith(ordem: ordem));

  void inverterOrdem() => emit(state.copyWith(ordem: state.ordem.invertida));

  void _aoMudarLista(List<ResumoProduto> lista) {
    if (isClosed) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoProdutos.pronto,
        todos: lista,
        mensagemErro: () => null,
      ),
    );
  }

  /// Com lista já na tela, a falha de uma recarga não apaga o que está visível.
  void _aoFalhar(String mensagem) {
    if (state.carregamento == CarregamentoProdutos.pronto) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoProdutos.erro,
        mensagemErro: () => mensagem,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _assinatura.cancel();
    return super.close();
  }
}
