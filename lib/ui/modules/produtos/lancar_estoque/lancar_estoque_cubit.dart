import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/item_lancamento.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/core/repository/repositorio_estoque.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/ui/modules/produtos/lancar_estoque/lancar_estoque_state.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

/// Uma compra para o estoque: data, itens e gravação de tudo de uma vez.
class LancarEstoqueCubit extends Cubit<LancarEstoqueState> {
  LancarEstoqueCubit({
    String? produtoInicialId,
    RepositorioProdutos? produtos,
    RepositorioEstoque? estoque,
    DateTime Function()? agora,
  }) : _produtos = produtos ?? injetor<RepositorioProdutos>(),
       _estoque = estoque ?? injetor<RepositorioEstoque>(),
       _agora = agora ?? DateTime.now,
       super(
         LancarEstoqueState(
           dataCompra: _dia((agora ?? DateTime.now)()),
           produtoInicialId: produtoInicialId,
         ),
       ) {
    // "Cadastrar novo produto": o produto novo chega pelo stream.
    _assinatura = _produtos.mudancas.listen(_aoMudarProdutos);
    carregarProdutos();
  }

  final RepositorioProdutos _produtos;
  final RepositorioEstoque _estoque;
  final DateTime Function() _agora;
  late final StreamSubscription<List<ResumoProduto>> _assinatura;

  Future<void> carregarProdutos() async {
    final emCache = _produtos.lista;
    if (emCache != null) {
      _aoMudarProdutos(emCache);
      return;
    }
    emit(state.copyWith(carregandoProdutos: true, erroProdutos: () => null));
    final resultado = await _produtos.carregar();
    if (isClosed) return;
    if (resultado case Erro(:final falha)) {
      emit(
        state.copyWith(
          carregandoProdutos: false,
          erroProdutos: () => falha.mensagem,
        ),
      );
    }
  }

  void alterarData(DateTime data) {
    final erro = LancamentoEstoque.validarData(data, hoje: _agora());
    emit(state.copyWith(dataCompra: _dia(data), erroData: () => erro));
  }

  /// A folha já abriu com o produto da rota; não abre de novo.
  void consumirProdutoInicial() =>
      emit(state.copyWith(produtoInicialId: () => null));

  /// Um produto entra uma vez só. Na edição, [indiceEditado] é ignorado.
  bool jaNaCompra(String produtoId, {int? indiceEditado}) {
    for (var i = 0; i < state.itens.length; i++) {
      if (i != indiceEditado && state.itens[i].produto.id == produtoId) {
        return true;
      }
    }
    return false;
  }

  void adicionarItem(ItemLancamento item) {
    if (jaNaCompra(item.produto.id)) {
      emit(
        state.copyWith(
          aviso: () =>
              const AvisoToast.aviso(LancamentoEstoque.mensagemRepetido),
        ),
      );
      return;
    }
    emit(state.copyWith(itens: [...state.itens, item]));
  }

  void substituirItem(int indice, ItemLancamento item) {
    final itens = [...state.itens]..[indice] = item;
    emit(state.copyWith(itens: itens));
  }

  void removerItem(int indice) {
    final itens = [...state.itens]..removeAt(indice);
    emit(state.copyWith(itens: itens));
  }

  void limparAviso() => emit(state.copyWith(aviso: () => null));

  Future<void> salvar() async {
    if (!state.podeSalvar) return;
    emit(state.copyWith(salvando: true));
    final resultado = await _estoque.lancar(state.lancamento);
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(
          state.copyWith(
            salvando: false,
            aviso: () => AvisoToast.erro(falha.mensagem),
          ),
        );
      case Sucesso():
        emit(state.copyWith(salvando: false, salvo: true));
    }
  }

  void _aoMudarProdutos(List<ResumoProduto> lista) {
    if (isClosed) return;
    emit(
      state.copyWith(
        produtos: lista,
        carregandoProdutos: false,
        erroProdutos: () => null,
      ),
    );
  }

  static DateTime _dia(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  @override
  Future<void> close() async {
    await _assinatura.cancel();
    return super.close();
  }
}
