import 'package:sou_consultora/core/model/filtro_clientes.dart';
import 'package:sou_consultora/core/model/ordem_nome.dart';
import 'package:sou_consultora/core/model/resumo_cliente.dart';

enum CarregamentoClientes { carregando, pronto, erro }

class ClientesListaState {
  const ClientesListaState({
    required this.hoje,
    this.carregamento = CarregamentoClientes.carregando,
    this.todas = const [],
    this.status = StatusFiltroCliente.todos,
    this.busca = '',
    this.ordem = OrdemNome.aZ,
    this.mensagemErro,
  });

  final DateTime hoje;
  final CarregamentoClientes carregamento;

  /// Todas as clientes da consultora (sem filtro).
  final List<ResumoCliente> todas;
  final StatusFiltroCliente status;
  final String busca;
  final OrdemNome ordem;
  final String? mensagemErro;

  /// Clientes exibidas, já filtradas, buscadas e ordenadas.
  List<ResumoCliente> get visiveis => FiltroClientes.aplicar(
    todas,
    status: status,
    busca: busca,
    ordem: ordem,
    hoje: hoje,
  );

  Map<StatusFiltroCliente, int> get contagens =>
      FiltroClientes.contagens(todas, hoje);

  ClientesListaState copyWith({
    CarregamentoClientes? carregamento,
    List<ResumoCliente>? todas,
    StatusFiltroCliente? status,
    String? busca,
    OrdemNome? ordem,
    String? Function()? mensagemErro,
  }) {
    return ClientesListaState(
      hoje: hoje,
      carregamento: carregamento ?? this.carregamento,
      todas: todas ?? this.todas,
      status: status ?? this.status,
      busca: busca ?? this.busca,
      ordem: ordem ?? this.ordem,
      mensagemErro: mensagemErro != null ? mensagemErro() : this.mensagemErro,
    );
  }
}
