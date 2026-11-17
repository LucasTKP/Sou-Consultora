import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/ui/modules/clientes/dados/clientes_dados_state.dart';

class ClientesDadosCubit extends Cubit<ClientesDadosState> {
  ClientesDadosCubit({
    required this.idCliente,
    RepositorioClientes? repositorio,
  }) : _repositorio = repositorio ?? injetor<RepositorioClientes>(),
       super(const ClientesDadosState()) {
    carregar();
  }

  final String idCliente;
  final RepositorioClientes _repositorio;

  Future<void> carregar() async {
    emit(state.copyWith(carregando: true, erro: () => null));
    final resultado = await _repositorio.buscarCliente(idCliente);
    if (isClosed) return;
    switch (resultado) {
      case Sucesso(valor: final Cliente cliente):
        emit(state.copyWith(cliente: cliente, carregando: false));
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

  Future<void> abrirWhatsapp() async {
    final cliente = state.cliente;
    if (cliente == null) return;
    final resultado = await _repositorio.abrirWhatsapp(cliente.whatsapp);
    if (isClosed) return;
    if (resultado case Erro(:final falha)) {
      emit(state.copyWith(aviso: () => falha.mensagem));
    }
  }

  void limparAviso() => emit(state.copyWith(aviso: () => null));
}
