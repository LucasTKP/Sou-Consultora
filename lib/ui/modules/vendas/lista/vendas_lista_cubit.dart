import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/venda.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/ui/modules/vendas/lista/vendas_lista_state.dart';

/// Lista de vendas: carrega, acompanha o repositório e guarda busca, status,
/// mês e ordem escolhidos na tela.
class VendasListaCubit extends Cubit<VendasListaState> {
  VendasListaCubit({RepositorioVendas? repositorio, DateTime Function()? agora})
    : _repositorio = repositorio ?? injetor<RepositorioVendas>(),
      super(_inicial((agora ?? DateTime.now)())) {
    final emCache = _repositorio.lista;
    if (emCache != null) _aoMudarLista(emCache);
    _assinatura = _repositorio.mudancas.listen(_aoMudarLista);
    carregar();
  }

  final RepositorioVendas _repositorio;
  late final StreamSubscription<List<ResumoVenda>> _assinatura;

  static VendasListaState _inicial(DateTime hoje) =>
      VendasListaState(hoje: hoje, mes: MesAno.de(hoje));

  Future<void> carregar() async {
    if (state.carregamento != CarregamentoVendas.pronto) {
      emit(state.copyWith(carregamento: CarregamentoVendas.carregando));
    }
    final resultado = await _repositorio.carregar();
    if (isClosed) return;
    if (resultado case Erro(:final falha)) _aoFalhar(falha.mensagem);
  }

  void alterarBusca(String busca) => emit(state.copyWith(busca: busca));

  void alterarStatus(StatusFiltroVenda status) =>
      emit(state.copyWith(status: status));

  /// Null = todos os meses.
  void alterarMes(MesAno? mes) => emit(state.copyWith(mes: () => mes));

  void alterarOrdem(OrdemData ordem) => emit(state.copyWith(ordem: ordem));

  void inverterOrdem() => emit(state.copyWith(ordem: state.ordem.invertida));

  void _aoMudarLista(List<ResumoVenda> lista) {
    if (isClosed) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoVendas.pronto,
        todas: lista,
        mensagemErro: () => null,
      ),
    );
  }

  void _aoFalhar(String mensagem) {
    if (state.carregamento == CarregamentoVendas.pronto) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoVendas.erro,
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
