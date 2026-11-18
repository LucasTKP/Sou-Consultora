import 'package:sou_consultora/core/model/filtro_recebimentos.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/parcela.dart';

enum CarregamentoRecebimentos { carregando, pronto, erro }

class AReceberListaState {
  const AReceberListaState({
    required this.hoje,
    required this.mes,
    this.carregamento = CarregamentoRecebimentos.carregando,
    this.todas = const [],
    this.status = StatusFiltroRecebimento.todos,
    this.busca = '',
    this.ordem = OrdemRecebimento.vencimentoProximo,
    this.mensagemErro,
  });

  final DateTime hoje;
  final CarregamentoRecebimentos carregamento;
  final List<ResumoParcela> todas;
  final StatusFiltroRecebimento status;

  /// Null = todos os meses (pelo vencimento).
  final MesAno? mes;
  final String busca;
  final OrdemRecebimento ordem;
  final String? mensagemErro;

  List<ResumoParcela> get visiveis => FiltroRecebimentos.aplicar(
    todas,
    status: status,
    mes: mes,
    busca: busca,
    ordem: ordem,
    hoje: hoje,
  );

  Map<StatusFiltroRecebimento, int> get contagens =>
      FiltroRecebimentos.contagens(todas, mes, hoje: hoje);

  List<MesAno> get meses => FiltroRecebimentos.meses(todas, hoje: hoje);

  AReceberListaState copyWith({
    CarregamentoRecebimentos? carregamento,
    List<ResumoParcela>? todas,
    StatusFiltroRecebimento? status,
    MesAno? Function()? mes,
    String? busca,
    OrdemRecebimento? ordem,
    String? Function()? mensagemErro,
  }) {
    return AReceberListaState(
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
