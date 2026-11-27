import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/venda.dart';

/// Faturamento (soma das vendas) de um mês. Centavos.
class FaturamentoMes {
  const FaturamentoMes(this.mes, this.valor);

  final MesAno mes;
  final int valor;
}

/// Números do Financeiro para um [periodo]: os 12 meses que terminam nele,
/// o total acumulado e as categorias do mês. Valores em centavos.
class ResumoFinanceiro {
  const ResumoFinanceiro({
    required this.periodo,
    required this.meses,
    required this.faturamentoDoMes,
    required this.despesasDoMes,
  });

  static const quantidadeMeses = 12;

  final MesAno periodo;

  /// Do mais antigo ao [periodo] (sempre 12, inclusive os sem vendas).
  final List<FaturamentoMes> meses;

  /// Soma das vendas com data de venda no [periodo].
  final int faturamentoDoMes;

  /// Soma dos boletos que vencem no [periodo], pagos ou não.
  final int despesasDoMes;

  int get totalAcumulado => meses.fold(0, (total, m) => total + m.valor);

  /// Maior faturamento entre os 12 meses (altura cheia do gráfico).
  int get maiorMes =>
      meses.fold(0, (maior, m) => m.valor > maior ? m.valor : maior);

  static ResumoFinanceiro calcular({
    required List<ResumoVenda> vendas,
    required List<ResumoBoleto> boletos,
    required MesAno periodo,
  }) {
    final porMes = <MesAno, int>{};
    for (final venda in vendas) {
      final mes = MesAno.de(venda.dataVenda);
      porMes[mes] = (porMes[mes] ?? 0) + venda.total;
    }
    final despesas = boletos
        .where((b) => periodo.contem(b.vencimento))
        .fold(0, (total, b) => total + b.valor);
    return ResumoFinanceiro(
      periodo: periodo,
      meses: [
        for (var i = quantidadeMeses - 1; i >= 0; i--)
          FaturamentoMes(periodo.somar(-i), porMes[periodo.somar(-i)] ?? 0),
      ],
      faturamentoDoMes: porMes[periodo] ?? 0,
      despesasDoMes: despesas,
    );
  }

  /// Meses que dá para escolher: os 12 até o mês atual e os que têm vendas
  /// ou boletos, do mais recente ao mais antigo.
  static List<MesAno> periodos({
    required List<ResumoVenda> vendas,
    required List<ResumoBoleto> boletos,
    required DateTime hoje,
  }) {
    final atual = MesAno.de(hoje);
    return {
      for (var i = 0; i < quantidadeMeses; i++) atual.somar(-i),
      for (final v in vendas) MesAno.de(v.dataVenda),
      for (final b in boletos) MesAno.de(b.vencimento),
    }.toList()..sort((a, b) => b.indice.compareTo(a.indice));
  }
}
