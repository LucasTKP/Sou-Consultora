import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/lembrete_recompra.dart';
import 'package:sou_consultora/core/model/pagamento.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/core/model/venda.dart';

/// Um boleto não pago que venceu, vence hoje ou vence amanhã.
class AlertaBoleto {
  const AlertaBoleto({required this.boleto, required this.diasParaVencer});

  final ResumoBoleto boleto;

  /// Negativo = venceu há N dias; 0 = hoje; 1 = amanhã.
  final int diasParaVencer;
}

/// Parcelas vencidas com saldo: quantas clientes e quanto falta.
class AlertaAtrasadas {
  const AlertaAtrasadas({
    required this.qtdClientes,
    required this.qtdParcelas,
    required this.total,
  });

  final int qtdClientes;
  final int qtdParcelas;

  /// Centavos (soma dos saldos).
  final int total;
}

/// Um lembrete dentro da janela, com a situação já calculada.
class LembreteAtivo {
  const LembreteAtivo({
    required this.lembrete,
    required this.situacao,
    required this.diasDesdeCompra,
  });

  final LembreteRecompra lembrete;
  final SituacaoLembrete situacao;
  final int diasDesdeCompra;
}

/// Números e alertas do Início para o dia [hoje]. Valores em centavos.
class ResumoInicio {
  const ResumoInicio({
    required this.vendidoNoMes,
    required this.qtdVendasNoMes,
    required this.recebidoNoMes,
    required this.boletosNoMes,
    required this.alertasBoletos,
    required this.atrasadas,
    required this.lembretes,
  });

  static const maxAlertasBoletos = 3;
  static const maxLembretes = 3;

  final int vendidoNoMes;
  final int qtdVendasNoMes;

  /// Pagamentos de parcelas com data de pagamento no mês (de qualquer venda).
  final int recebidoNoMes;

  /// Boletos que vencem no mês, pagos ou não (como no Financeiro).
  final int boletosNoMes;

  /// Até 3, do mais atrasado ao mais próximo.
  final List<AlertaBoleto> alertasBoletos;

  /// Null sem parcelas atrasadas.
  final AlertaAtrasadas? atrasadas;

  /// Até 3, do mais urgente (mais dias desde a previsão) ao menos.
  final List<LembreteAtivo> lembretes;

  int get qtdAlertas => alertasBoletos.length + (atrasadas == null ? 0 : 1);

  static ResumoInicio calcular({
    required List<ResumoVenda> vendas,
    required List<Pagamento> pagamentos,
    required List<ResumoParcela> parcelas,
    required List<ResumoBoleto> boletos,
    required List<LembreteRecompra> lembretes,
    required DateTime hoje,
  }) {
    final mes = MesAno.de(hoje);
    final doMes = vendas.where((v) => mes.contem(v.dataVenda)).toList();
    return ResumoInicio(
      vendidoNoMes: _soma(doMes.map((v) => v.total)),
      qtdVendasNoMes: doMes.length,
      recebidoNoMes: _soma(
        pagamentos.where((p) => mes.contem(p.data)).map((p) => p.valor),
      ),
      boletosNoMes: _soma(
        boletos.where((b) => mes.contem(b.vencimento)).map((b) => b.valor),
      ),
      alertasBoletos: alertasDeBoletos(boletos, hoje: hoje),
      atrasadas: atrasadasDe(parcelas, hoje: hoje),
      lembretes: lembretesAtivos(
        lembretes,
        hoje: hoje,
      ).take(maxLembretes).toList(),
    );
  }

  static List<AlertaBoleto> alertasDeBoletos(
    List<ResumoBoleto> boletos, {
    required DateTime hoje,
  }) {
    final alertas = [
      for (final b in boletos)
        if (!b.pago && b.diasAteVencimento(hoje: hoje) <= 1)
          AlertaBoleto(
            boleto: b,
            diasParaVencer: b.diasAteVencimento(hoje: hoje),
          ),
    ]..sort((a, b) => a.diasParaVencer.compareTo(b.diasParaVencer));
    return alertas.take(maxAlertasBoletos).toList();
  }

  static AlertaAtrasadas? atrasadasDe(
    List<ResumoParcela> parcelas, {
    required DateTime hoje,
  }) {
    final atrasadas = [
      for (final p in parcelas)
        if (p.status(hoje: hoje) == StatusParcela.atrasada) p,
    ];
    if (atrasadas.isEmpty) return null;
    return AlertaAtrasadas(
      qtdClientes: {for (final p in atrasadas) p.clienteId}.length,
      qtdParcelas: atrasadas.length,
      total: _soma(atrasadas.map((p) => p.saldo)),
    );
  }

  /// Todos os lembretes dentro da janela, do mais urgente ao menos.
  static List<LembreteAtivo> lembretesAtivos(
    List<LembreteRecompra> lembretes, {
    required DateTime hoje,
  }) {
    final ativos = <(int, LembreteAtivo)>[];
    for (final l in lembretes) {
      final situacao = l.situacao(hoje: hoje);
      if (situacao == null) continue;
      ativos.add((
        l.diasDesdePrevisao(hoje: hoje),
        LembreteAtivo(
          lembrete: l,
          situacao: situacao,
          diasDesdeCompra: l.diasDesdeCompra(hoje: hoje),
        ),
      ));
    }
    ativos.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final (_, ativo) in ativos) ativo];
  }

  static int _soma(Iterable<int> valores) =>
      valores.fold(0, (total, v) => total + v);
}
