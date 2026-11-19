import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/filtro_clientes.dart';
import 'package:sou_consultora/core/model/ordem_nome.dart';
import 'package:sou_consultora/core/model/resumo_cliente.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/ui/modules/clientes/lista/clientes_lista_state.dart';

/// Lista de clientes: carrega, acompanha as alterações do repositório e
/// guarda busca, filtro e ordem escolhidos na tela.
class ClientesListaCubit extends Cubit<ClientesListaState> {
  ClientesListaCubit({
    RepositorioClientes? repositorio,
    DateTime Function()? agora,
  }) : _repositorio = repositorio ?? injetor<RepositorioClientes>(),
       super(ClientesListaState(hoje: (agora ?? DateTime.now)())) {
    final emCache = _repositorio.lista;
    if (emCache != null) _aoMudarLista(emCache);
    _assinatura = _repositorio.mudancas.listen(_aoMudarLista);
    carregar();
  }

  final RepositorioClientes _repositorio;
  late final StreamSubscription<List<ResumoCliente>> _assinatura;

  Future<void> carregar() async {
    if (state.carregamento != CarregamentoClientes.pronto) {
      emit(state.copyWith(carregamento: CarregamentoClientes.carregando));
    }
    final resultado = await _repositorio.carregar();
    if (isClosed) return;
    // O sucesso chega pelo stream; aqui só trata a falha.
    if (resultado case Erro(:final falha)) _aoFalhar(falha.mensagem);
  }

  void alterarBusca(String busca) => emit(state.copyWith(busca: busca));

  void alterarStatus(StatusFiltroCliente status) =>
      emit(state.copyWith(status: status));

  void alterarOrdem(OrdemNome ordem) => emit(state.copyWith(ordem: ordem));

  void inverterOrdem() => emit(state.copyWith(ordem: state.ordem.inversa));

  void _aoMudarLista(List<ResumoCliente> lista) {
    if (isClosed) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoClientes.pronto,
        todas: lista,
        mensagemErro: () => null,
      ),
    );
  }

  /// Com lista já na tela, a falha de uma recarga não apaga o que está visível.
  void _aoFalhar(String mensagem) {
    if (state.carregamento == CarregamentoClientes.pronto) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoClientes.erro,
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
