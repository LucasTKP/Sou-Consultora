import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/filtro_fornecedores.dart';
import 'package:sou_consultora/core/model/ordem_nome.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/ui/modules/fornecedores/lista/fornecedores_lista_state.dart';

/// Lista de fornecedores: carrega, acompanha as alterações do repositório e
/// guarda busca, filtro e ordem escolhidos na tela.
class FornecedoresListaCubit extends Cubit<FornecedoresListaState> {
  FornecedoresListaCubit({RepositorioFornecedores? repositorio})
    : _repositorio = repositorio ?? injetor<RepositorioFornecedores>(),
      super(const FornecedoresListaState()) {
    final emCache = _repositorio.lista;
    if (emCache != null) _aoMudarLista(emCache);
    _assinatura = _repositorio.mudancas.listen(_aoMudarLista);
    carregar();
  }

  final RepositorioFornecedores _repositorio;
  late final StreamSubscription<List<ResumoFornecedor>> _assinatura;

  Future<void> carregar() async {
    if (state.carregamento != CarregamentoFornecedores.pronto) {
      emit(state.copyWith(carregamento: CarregamentoFornecedores.carregando));
    }
    final resultado = await _repositorio.carregar();
    if (isClosed) return;
    // O sucesso chega pelo stream; aqui só trata a falha.
    if (resultado case Erro(:final falha)) _aoFalhar(falha.mensagem);
  }

  void alterarBusca(String busca) => emit(state.copyWith(busca: busca));

  void alterarStatus(StatusFiltroFornecedor status) =>
      emit(state.copyWith(status: status));

  void alterarOrdem(OrdemNome ordem) => emit(state.copyWith(ordem: ordem));

  void inverterOrdem() => emit(state.copyWith(ordem: state.ordem.inversa));

  void _aoMudarLista(List<ResumoFornecedor> lista) {
    if (isClosed) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoFornecedores.pronto,
        todos: lista,
        mensagemErro: () => null,
      ),
    );
  }

  /// Com lista já na tela, a falha de uma recarga não apaga o que está visível.
  void _aoFalhar(String mensagem) {
    if (state.carregamento == CarregamentoFornecedores.pronto) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoFornecedores.erro,
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
