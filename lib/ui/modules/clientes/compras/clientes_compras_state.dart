import 'package:sou_consultora/core/model/detalhe_venda.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/venda.dart';

class ClientesComprasState {
  const ClientesComprasState({
    required this.hoje,
    this.clienteNome,
    this.compras,
    this.carregando = true,
    this.erro,
    this.status = StatusFiltroVenda.todas,
    this.busca = '',
  });

  final DateTime hoje;
  final String? clienteNome;
  final ComprasCliente? compras;
  final bool carregando;
  final String? erro;
  final StatusFiltroVenda status;
  final String busca;

  /// Compras filtradas e buscadas, das mais recentes para as mais antigas.
  List<ResumoVenda> get visiveis => FiltroVendas.aplicar(
    compras?.vendas ?? const [],
    status: status,
    mes: null,
    busca: busca,
    ordem: OrdemData.recentes,
  );

  Map<StatusFiltroVenda, int> get contagens =>
      FiltroVendas.contagens(compras?.vendas ?? const [], null);

  ClientesComprasState copyWith({
    String? clienteNome,
    ComprasCliente? compras,
    bool? carregando,
    String? Function()? erro,
    StatusFiltroVenda? status,
    String? busca,
  }) {
    return ClientesComprasState(
      hoje: hoje,
      clienteNome: clienteNome ?? this.clienteNome,
      compras: compras ?? this.compras,
      carregando: carregando ?? this.carregando,
      erro: erro != null ? erro() : this.erro,
      status: status ?? this.status,
      busca: busca ?? this.busca,
    );
  }
}
