import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/filtro_recebimentos.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/core/repository/repositorio_recebimentos.dart';
import 'package:sou_consultora/ui/modules/a_receber/lista/a_receber_lista_state.dart';

/// A receber: carrega as parcelas, acompanha o repositório e guarda busca,
/// status, mês e ordem escolhidos na tela.
class AReceberListaCubit extends Cubit<AReceberListaState> {
  AReceberListaCubit({
    RepositorioRecebimentos? repositorio,
    DateTime Function()? agora,
  }) : _repositorio = repositorio ?? injetor<RepositorioRecebimentos>(),
       super(_inicial((agora ?? DateTime.now)())) {
    final emCache = _repositorio.lista;
    if (emCache != null) _aoMudarLista(emCache);
    _assinatura = _repositorio.mudancas.listen(_aoMudarLista);
    carregar();
  }

  final RepositorioRecebimentos _repositorio;
  late final StreamSubscription<List<ResumoParcela>> _assinatura;

  static AReceberListaState _inicial(DateTime hoje) =>
      AReceberListaState(hoje: hoje, mes: MesAno.de(hoje));

  Future<void> carregar() async {
    if (state.carregamento != CarregamentoRecebimentos.pronto) {
      emit(state.copyWith(carregamento: CarregamentoRecebimentos.carregando));
    }
    final resultado = await _repositorio.carregar();
    if (isClosed) return;
    if (resultado case Erro(:final falha)) _aoFalhar(falha.mensagem);
  }

  void alterarBusca(String busca) => emit(state.copyWith(busca: busca));

  void alterarStatus(StatusFiltroRecebimento status) =>
      emit(state.copyWith(status: status));

  /// Null = todos os meses.
  void alterarMes(MesAno? mes) => emit(state.copyWith(mes: () => mes));

  void alterarOrdem(OrdemRecebimento ordem) =>
      emit(state.copyWith(ordem: ordem));

  void _aoMudarLista(List<ResumoParcela> lista) {
    if (isClosed) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoRecebimentos.pronto,
        todas: lista,
        mensagemErro: () => null,
      ),
    );
  }

  void _aoFalhar(String mensagem) {
    if (state.carregamento == CarregamentoRecebimentos.pronto) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoRecebimentos.erro,
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
