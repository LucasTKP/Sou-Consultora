/// Uma parcela combinada no passo 2 (antes de gravar). Valor em centavos.
class ParcelaPlano {
  const ParcelaPlano({required this.valor, required this.vencimento});

  final int valor;
  final DateTime vencimento;

  ParcelaPlano copyWith({int? valor, DateTime? vencimento}) => ParcelaPlano(
    valor: valor ?? this.valor,
    vencimento: vencimento ?? this.vencimento,
  );

  Map<String, dynamic> paraGravar() => {
    'valor': valor / 100,
    'data_vencimento':
        '${vencimento.year.toString().padLeft(4, '0')}-'
        '${vencimento.month.toString().padLeft(2, '0')}-'
        '${vencimento.day.toString().padLeft(2, '0')}',
  };
}

/// Regras do parcelamento (puras, sem Flutter).
abstract final class PlanoParcelas {
  static const minimoDividido = 2;
  static const maximo = 12;

  /// Valores iguais (centavos que sobram na última) com vencimentos mês a mês.
  static List<ParcelaPlano> sugerir({
    required int total,
    required int quantidade,
    required DateTime primeiroVencimento,
  }) {
    final base = total ~/ quantidade;
    final resto = total - base * quantidade;
    return [
      for (var i = 0; i < quantidade; i++)
        ParcelaPlano(
          valor: i == quantidade - 1 ? base + resto : base,
          vencimento: somarMeses(primeiroVencimento, i),
        ),
    ];
  }

  /// Total − soma das parcelas (positivo = falta; negativo = sobra).
  static int diferenca(int total, List<ParcelaPlano> parcelas) =>
      total - parcelas.fold(0, (soma, p) => soma + p.valor);

  /// Parcelas válidas: todas com valor > 0 e soma igual ao total.
  static bool fecha(int total, List<ParcelaPlano> parcelas) =>
      parcelas.isNotEmpty &&
      parcelas.every((p) => p.valor > 0) &&
      diferenca(total, parcelas) == 0;

  /// 31/01 + 1 mês → 28/02 (ou 29/02): fica no último dia do mês.
  static DateTime somarMeses(DateTime data, int meses) {
    final ano = data.year + (data.month - 1 + meses) ~/ 12;
    final mes = (data.month - 1 + meses) % 12 + 1;
    final ultimoDia = DateTime(ano, mes + 1, 0).day;
    final dia = data.day > ultimoDia ? ultimoDia : data.day;
    return DateTime(ano, mes, dia);
  }
}
