import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/venda.dart';

enum CarregamentoVendas { carregando, pronto, erro }

class VendasListaState {
  const VendasListaState({
    required this.hoje,
    required this.mes,
    this.carregamento = CarregamentoVendas.carregando,
    this.todas = const [],
    this.status = StatusFiltroVenda.todas,
    this.busca = '',
    this.ordem = OrdemData.recentes,
    this.mensagemErro,
  });

  final DateTime hoje;
  final CarregamentoVendas carregamento;
  final List<ResumoVenda> todas;
  final StatusFiltroVenda status;

  /// Null = todos os meses.
  final MesAno? mes;
  final String busca;
  final OrdemData ordem;
  final String? mensagemErro;

  List<ResumoVenda> get visiveis => FiltroVendas.aplicar(
    todas,
    status: status,
    mes: mes,
    busca: busca,
    ordem: ordem,
  );

  Map<StatusFiltroVenda, int> get contagens =>
      FiltroVendas.contagens(todas, mes);

  List<MesAno> get meses => FiltroVendas.meses(todas, hoje: hoje);

  /// Vendas do mês (ou de todos), antes da busca e do status.
  int get totalDoPeriodo => FiltroVendas.doMes(todas, mes).length;

  VendasListaState copyWith({
    CarregamentoVendas? carregamento,
    List<ResumoVenda>? todas,
    StatusFiltroVenda? status,
    MesAno? Function()? mes,
    String? busca,
    OrdemData? ordem,
    String? Function()? mensagemErro,
  }) {
    return VendasListaState(
      hoje: hoje,
      carregamento: carregamento ?? this.carregamento,
      todas: todas ?? this.todas,
      status: status ?? this.status,
      mes: mes != null ? mes() : this.mes,
      busca: busca ?? this.busca,
      ordem: ordem ?? this.ordem,
      mensagemErro: mensagemErro != null ? mensagemErro() : this.mensagemErro,
    );
  }
}
