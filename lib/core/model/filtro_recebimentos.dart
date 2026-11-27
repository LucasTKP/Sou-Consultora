import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/core/model/texto_busca.dart';

/// Opções do filtro de status de A receber.
enum StatusFiltroRecebimento {
  todos('Todos'),
  aReceber('A receber'),
  atrasado('Atrasado'),
  venceHoje('Vence hoje'),
  pago('Pago');

  const StatusFiltroRecebimento(this.rotulo);

  final String rotulo;

  /// `?status=atrasado` / `?status=pago` (vindo do Início); null se não houver
  /// ou não for reconhecido.
  static StatusFiltroRecebimento? doParametro(String? valor) => switch (valor) {
    'atrasado' => atrasado,
    'pago' => pago,
    'a-receber' => aReceber,
    'vence-hoje' => venceHoje,
    _ => null,
  };

  bool aceita(ResumoParcela parcela, {required DateTime hoje}) {
    final status = parcela.status(hoje: hoje);
    final hojeVence = parcela.venceHoje(hoje: hoje);
    return switch (this) {
      todos => true,
      aReceber =>
        (status == StatusParcela.aReceber || status == StatusParcela.parcial) &&
            !hojeVence,
      atrasado => status == StatusParcela.atrasada,
      venceHoje => hojeVence,
      pago => status == StatusParcela.pago,
    };
  }
}

/// Ordem da lista de recebimentos.
enum OrdemRecebimento {
  vencimentoProximo('Vencimento: mais próximo'),
  vencimentoDistante('Vencimento: mais distante'),
  maiorValor('Maior valor'),
  menorValor('Menor valor');

  const OrdemRecebimento(this.rotulo);

  final String rotulo;
}

/// Regras de busca, filtro e ordem de A receber (puras, sem Flutter).
abstract final class FiltroRecebimentos {
  static List<ResumoParcela> doMes(List<ResumoParcela> parcelas, MesAno? mes) =>
      mes == null
      ? parcelas
      : parcelas.where((p) => mes.contem(p.vencimento)).toList();

  static bool combinaBusca(ResumoParcela parcela, String busca) =>
      TextoBusca.contem(parcela.clienteNome, busca) ||
      TextoBusca.contem(parcela.nomesItens, busca);

  static List<ResumoParcela> aplicar(
    List<ResumoParcela> parcelas, {
    required StatusFiltroRecebimento status,
    required MesAno? mes,
    required String busca,
    required OrdemRecebimento ordem,
    required DateTime hoje,
  }) {
    return doMes(parcelas, mes)
        .where((p) => status.aceita(p, hoje: hoje) && combinaBusca(p, busca))
        .toList()
      ..sort((a, b) => _comparar(a, b, ordem));
  }

  static Map<StatusFiltroRecebimento, int> contagens(
    List<ResumoParcela> parcelas,
    MesAno? mes, {
    required DateTime hoje,
  }) {
    final doMesEscolhido = doMes(parcelas, mes);
    return {
      for (final status in StatusFiltroRecebimento.values)
        status: doMesEscolhido
            .where((p) => status.aceita(p, hoje: hoje))
            .length,
    };
  }

  /// Meses com vencimentos, mais o mês atual, do mais recente ao mais antigo.
  static List<MesAno> meses(
    List<ResumoParcela> parcelas, {
    required DateTime hoje,
  }) {
    return {
        MesAno.de(hoje),
        for (final p in parcelas) MesAno.de(p.vencimento),
      }.toList()
      ..sort((a, b) => (b.ano * 12 + b.mes).compareTo(a.ano * 12 + a.mes));
  }

  /// Valor mostrado no card: o saldo (ou o valor, se já está paga).
  static int valorExibido(ResumoParcela p) => p.paga ? p.valor : p.saldo;

  static int _comparar(
    ResumoParcela a,
    ResumoParcela b,
    OrdemRecebimento o,
  ) => switch (o) {
    OrdemRecebimento.vencimentoProximo => a.vencimento.compareTo(b.vencimento),
    OrdemRecebimento.vencimentoDistante => b.vencimento.compareTo(a.vencimento),
    OrdemRecebimento.maiorValor => valorExibido(b).compareTo(valorExibido(a)),
    OrdemRecebimento.menorValor => valorExibido(a).compareTo(valorExibido(b)),
  };
}
