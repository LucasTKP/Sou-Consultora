import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/venda.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/ui/modules/clientes/compras/clientes_compras_state.dart';

/// Compras de uma cliente: vendas, parcelas e totais. Recarrega quando as
/// vendas mudam (nova venda, pagamento, cancelamento).
class ClientesComprasCubit extends Cubit<ClientesComprasState> {
  ClientesComprasCubit({
    required this.idCliente,
    RepositorioVendas? vendas,
    RepositorioClientes? clientes,
    DateTime Function()? agora,
  }) : _vendas = vendas ?? injetor<RepositorioVendas>(),
       _clientes = clientes ?? injetor<RepositorioClientes>(),
       super(ClientesComprasState(hoje: (agora ?? DateTime.now)())) {
    _assinatura = _vendas.mudancas.listen((_) => carregar());
    carregar();
  }

  final String idCliente;
  final RepositorioVendas _vendas;
  final RepositorioClientes _clientes;
  late final StreamSubscription<List<ResumoVenda>> _assinatura;

  Future<void> carregar() async {
    if (state.compras == null) {
      emit(state.copyWith(carregando: true, erro: () => null));
    }
    final nome = await _nomeDaCliente();
    final resultado = await _vendas.compras(idCliente);
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(state.copyWith(carregando: false, erro: () => falha.mensagem));
      case Sucesso(:final valor):
        emit(
          state.copyWith(
            clienteNome: nome,
            compras: valor,
            carregando: false,
            erro: () => null,
          ),
        );
    }
  }

  void alterarStatus(StatusFiltroVenda status) =>
      emit(state.copyWith(status: status));

  void alterarBusca(String busca) => emit(state.copyWith(busca: busca));

  Future<String?> _nomeDaCliente() async {
    final emCache = _clientes.resumoEmCache(idCliente);
    if (emCache != null) return emCache.nome;
    final resultado = await _clientes.buscarResumo(idCliente);
    return switch (resultado) {
      Sucesso(:final valor) => valor?.nome,
      Erro() => null,
    };
  }

  @override
  Future<void> close() async {
    await _assinatura.cancel();
    return super.close();
  }
}
