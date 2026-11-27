import 'package:sou_consultora/core/model/lote_produto.dart';

/// Números do estoque de um produto, calculados dos lotes (nada gravado).
/// Valores em centavos.
class ResumoEstoque {
  const ResumoEstoque._({
    required this.saldo,
    required this.custoMedio,
    required this.valorEmEstoque,
  });

  factory ResumoEstoque.dosLotes(List<LoteProduto> lotes) {
    var saldo = 0;
    var valor = 0;
    for (final lote in lotes) {
      saldo += lote.disponivel;
      valor += lote.disponivel * lote.custoUnitario;
    }
    return ResumoEstoque._(
      saldo: saldo,
      // Média ponderada pelo disponível, arredondada ao centavo.
      custoMedio: saldo == 0 ? 0 : (valor / saldo).round(),
      valorEmEstoque: valor,
    );
  }

  /// Unidades disponíveis.
  final int saldo;
  final int custoMedio;
  final int valorEmEstoque;

  bool get prontaEntrega => saldo > 0;
}
