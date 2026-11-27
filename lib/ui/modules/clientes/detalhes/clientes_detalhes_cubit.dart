import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/resumo_cliente.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/ui/modules/clientes/detalhes/clientes_detalhes_state.dart';

/// Detalhes da cliente: mostra o que está na lista na hora e atualiza pela rede.
/// Acompanha as alterações (ex.: edição) pelo stream do repositório.
class ClientesDetalhesCubit extends Cubit<ClientesDetalhesState> {
  ClientesDetalhesCubit({
    required this.idCliente,
    RepositorioClientes? repositorio,
    DateTime Function()? agora,
  }) : _repositorio = repositorio ?? injetor<RepositorioClientes>(),
       super(ClientesDetalhesState(hoje: (agora ?? DateTime.now)())) {
    final emCache = _repositorio.resumoEmCache(idCliente);
    if (emCache != null) emit(state.copyWith(resumo: emCache));
    _assinatura = _repositorio.mudancas.listen(_aoMudarLista);
    carregar();
  }

  final String idCliente;
  final RepositorioClientes _repositorio;
  late final StreamSubscription<List<ResumoCliente>> _assinatura;

  Future<void> carregar() async {
    emit(state.copyWith(carregando: true, erro: () => null));
    final resultado = await _repositorio.buscarResumo(idCliente);
    if (isClosed) return;
    switch (resultado) {
      case Sucesso(valor: final ResumoCliente resumo):
        emit(state.copyWith(resumo: resumo, carregando: false));
      case Sucesso(valor: null):
        emit(
          state.copyWith(
            carregando: false,
            erro: () => 'Cliente não encontrada.',
          ),
        );
      case Erro(:final falha):
        emit(state.copyWith(carregando: false, erro: () => falha.mensagem));
    }
  }

  void _aoMudarLista(List<ResumoCliente> lista) {
    if (isClosed) return;
    for (final cliente in lista) {
      if (cliente.id == idCliente) emit(state.copyWith(resumo: cliente));
    }
  }

  @override
  Future<void> close() async {
    await _assinatura.cancel();
    return super.close();
  }
}
