import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/core/model/filtro_boletos.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/repository/repositorio_boletos.dart';
import 'package:sou_consultora/ui/modules/a_pagar/lista/a_pagar_lista_state.dart';

/// A pagar: carrega os boletos, acompanha o repositório e guarda busca,
/// status e mês escolhidos. Com [fornecedorId], mostra só aquela marca e
/// começa em "Todos os meses".
class APagarListaCubit extends Cubit<APagarListaState> {
  APagarListaCubit({
    this.fornecedorId,
    RepositorioBoletos? repositorio,
    DateTime Function()? agora,
  }) : _repositorio = repositorio ?? injetor<RepositorioBoletos>(),
       super(_inicial((agora ?? DateTime.now)(), fornecedorId)) {
    final emCache = _repositorio.lista;
    if (emCache != null) _aoMudarLista(emCache);
    _assinatura = _repositorio.mudancas.listen(_aoMudarLista);
    carregar();
  }

  final String? fornecedorId;
  final RepositorioBoletos _repositorio;
  late final StreamSubscription<List<ResumoBoleto>> _assinatura;

  static APagarListaState _inicial(DateTime hoje, String? fornecedorId) =>
      APagarListaState(
        hoje: hoje,
        fornecedorId: fornecedorId,
        mes: fornecedorId == null ? MesAno.de(hoje) : null,
      );

  Future<void> carregar() async {
    if (state.carregamento != CarregamentoBoletos.pronto) {
      emit(state.copyWith(carregamento: CarregamentoBoletos.carregando));
    }
    final resultado = await _repositorio.carregar();
    if (isClosed) return;
    if (resultado case Erro(:final falha)) _aoFalhar(falha.mensagem);
  }

  void alterarBusca(String busca) => emit(state.copyWith(busca: busca));

  void alterarStatus(StatusFiltroBoleto status) =>
      emit(state.copyWith(status: status));

  /// Null = todos os meses.
  void alterarMes(MesAno? mes) => emit(state.copyWith(mes: () => mes));

  void alterarOrdem(OrdemBoleto ordem) => emit(state.copyWith(ordem: ordem));

  void _aoMudarLista(List<ResumoBoleto> lista) {
    if (isClosed) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoBoletos.pronto,
        todos: lista,
        mensagemErro: () => null,
      ),
    );
  }

  void _aoFalhar(String mensagem) {
    if (state.carregamento == CarregamentoBoletos.pronto) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoBoletos.erro,
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
