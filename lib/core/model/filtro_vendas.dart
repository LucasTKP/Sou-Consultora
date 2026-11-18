import 'package:sou_consultora/core/model/venda.dart';

/// Opções do filtro de status da lista de vendas.
enum StatusFiltroVenda {
  todas('Todas as vendas'),
  emAberto('Em aberto'),
  atrasada('Atrasadas'),
  quitada('Quitadas');

  const StatusFiltroVenda(this.rotulo);

  final String rotulo;

  bool aceita(ResumoVenda venda) => switch (this) {
    todas => true,
    emAberto => venda.status == StatusVenda.emAberto,
    atrasada => venda.status == StatusVenda.atrasada,
    quitada => venda.status == StatusVenda.quitada,
  };
}

/// Ordem da lista de vendas pela data.
enum OrdemData {
  recentes('Data: Mais recentes'),
  antigas('Data: Mais antigas');

  const OrdemData(this.rotulo);

  final String rotulo;

  OrdemData get invertida => this == recentes ? antigas : recentes;
}

/// Um mês do filtro (null = todos os meses).
class MesAno {
  const MesAno(this.ano, this.mes);

  factory MesAno.de(DateTime data) => MesAno(data.year, data.month);

  final int ano;
  final int mes;

  bool contem(DateTime data) => data.year == ano && data.month == mes;

  @override
  bool operator ==(Object other) =>
      other is MesAno && other.ano == ano && other.mes == mes;

  @override
  int get hashCode => Object.hash(ano, mes);
}

/// Regras de busca, filtro e ordem da lista de vendas (puras, sem Flutter).
abstract final class FiltroVendas {
  static List<ResumoVenda> doMes(List<ResumoVenda> vendas, MesAno? mes) =>
      mes == null
      ? vendas
      : vendas.where((v) => mes.contem(v.dataVenda)).toList();

  static List<ResumoVenda> aplicar(
    List<ResumoVenda> vendas, {
    required StatusFiltroVenda status,
    required MesAno? mes,
    required String busca,
    required OrdemData ordem,
  }) {
    final filtradas =
        doMes(
            vendas,
            mes,
          ).where((v) => status.aceita(v) && v.combinaBusca(busca)).toList()
          ..sort((a, b) => b.dataVenda.compareTo(a.dataVenda));
    return ordem == OrdemData.recentes
        ? filtradas
        : filtradas.reversed.toList();
  }

  /// Quantidade de vendas do mês em cada status.
  static Map<StatusFiltroVenda, int> contagens(
    List<ResumoVenda> vendas,
    MesAno? mes,
  ) {
    final doMesEscolhido = doMes(vendas, mes);
    return {
      for (final status in StatusFiltroVenda.values)
        status: doMesEscolhido.where(status.aceita).length,
    };
  }

  /// Meses com vendas, mais o mês atual, do mais recente ao mais antigo.
  static List<MesAno> meses(
    List<ResumoVenda> vendas, {
    required DateTime hoje,
  }) {
    final meses =
        {
            MesAno.de(hoje),
            for (final v in vendas) MesAno.de(v.dataVenda),
          }.toList()
          ..sort((a, b) => (b.ano * 12 + b.mes).compareTo(a.ano * 12 + a.mes));
    return meses;
  }
}
