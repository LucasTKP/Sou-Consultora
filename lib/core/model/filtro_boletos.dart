import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/texto_busca.dart';

/// Opções do filtro de status de A pagar.
enum StatusFiltroBoleto {
  todos('Todos'),
  pendente('Pendente'),
  venceHoje('Vence hoje'),
  atrasado('Atrasado'),
  pago('Pago');

  const StatusFiltroBoleto(this.rotulo);

  final String rotulo;

  bool aceita(ResumoBoleto boleto, {required DateTime hoje}) {
    final status = boleto.status(hoje: hoje);
    return switch (this) {
      todos => true,
      pendente => status == StatusBoleto.pendente,
      venceHoje => status == StatusBoleto.venceHoje,
      atrasado => status == StatusBoleto.atrasado,
      pago => status == StatusBoleto.pago,
    };
  }
}

/// Ordem da lista de boletos. Igual à de A receber.
enum OrdemBoleto {
  vencimentoProximo('Vencimento: mais próximo'),
  vencimentoDistante('Vencimento: mais distante'),
  maiorValor('Maior valor'),
  menorValor('Menor valor');

  const OrdemBoleto(this.rotulo);

  final String rotulo;
}

/// Regras de busca, filtro e ordem de A pagar (puras, sem Flutter).
abstract final class FiltroBoletos {
  /// Mês pelo vencimento ([mes] nulo = todos) e, se informado, só do fornecedor.
  static List<ResumoBoleto> doRecorte(
    List<ResumoBoleto> boletos, {
    required MesAno? mes,
    String? fornecedorId,
  }) => [
    for (final b in boletos)
      if ((mes == null || mes.contem(b.vencimento)) &&
          (fornecedorId == null || b.fornecedorId == fornecedorId))
        b,
  ];

  /// Pela marca ou pela observação, sem acento.
  static bool combinaBusca(ResumoBoleto boleto, String busca) =>
      TextoBusca.contem(boleto.fornecedorNome, busca) ||
      TextoBusca.contem(boleto.observacoes ?? '', busca);

  static List<ResumoBoleto> aplicar(
    List<ResumoBoleto> boletos, {
    required StatusFiltroBoleto status,
    required MesAno? mes,
    required String busca,
    required OrdemBoleto ordem,
    required DateTime hoje,
    String? fornecedorId,
  }) {
    return doRecorte(boletos, mes: mes, fornecedorId: fornecedorId)
        .where((b) => status.aceita(b, hoje: hoje) && combinaBusca(b, busca))
        .toList()
      ..sort((a, b) => _comparar(a, b, ordem));
  }

  static Map<StatusFiltroBoleto, int> contagens(
    List<ResumoBoleto> boletos, {
    required MesAno? mes,
    required DateTime hoje,
    String? fornecedorId,
  }) {
    final recorte = doRecorte(boletos, mes: mes, fornecedorId: fornecedorId);
    return {
      for (final status in StatusFiltroBoleto.values)
        status: recorte.where((b) => status.aceita(b, hoje: hoje)).length,
    };
  }

  /// Meses com vencimentos, mais o mês atual, do mais recente ao mais antigo.
  static List<MesAno> meses(
    List<ResumoBoleto> boletos, {
    required DateTime hoje,
  }) {
    return {
        MesAno.de(hoje),
        for (final b in boletos) MesAno.de(b.vencimento),
      }.toList()
      ..sort((a, b) => (b.ano * 12 + b.mes).compareTo(a.ano * 12 + a.mes));
  }

  static int _comparar(ResumoBoleto a, ResumoBoleto b, OrdemBoleto ordem) {
    final resultado = switch (ordem) {
      OrdemBoleto.vencimentoProximo => a.vencimento.compareTo(b.vencimento),
      OrdemBoleto.vencimentoDistante => b.vencimento.compareTo(a.vencimento),
      OrdemBoleto.maiorValor => b.valor.compareTo(a.valor),
      OrdemBoleto.menorValor => a.valor.compareTo(b.valor),
    };
    if (resultado != 0) return resultado;
    return a.vencimento.compareTo(b.vencimento);
  }
}
