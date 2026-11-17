import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';

/// Um produto da compra: quantidade, custo unitário (centavos) e validade.
class ItemLancamento {
  const ItemLancamento({
    required this.produto,
    required this.quantidade,
    required this.custoUnitario,
    this.validade,
  });

  final ResumoProduto produto;
  final int quantidade;
  final int custoUnitario;
  final DateTime? validade;

  int get total => quantidade * custoUnitario;

  /// Formato da função `lancar_estoque`.
  Map<String, dynamic> paraGravar() => {
    'produto_id': produto.id,
    'quantidade': quantidade,
    'custo_unitario': custoUnitario / 100,
    'validade': ConversoresDto.textoData(validade),
  };

  static String? validarProduto(ResumoProduto? produto) =>
      produto == null ? 'Escolha o produto' : null;

  static String? validarQuantidade(int quantidade) =>
      quantidade < 1 ? 'Informe pelo menos 1 unidade' : null;

  static String? validarCusto(int? centavos) =>
      centavos == null || centavos <= 0 ? 'Informe o custo unitário' : null;

  /// A validade é opcional, mas não pode ser antes da data da compra.
  static String? validarValidade(DateTime? validade, DateTime dataCompra) {
    if (validade == null) return null;
    return _dia(validade).isBefore(_dia(dataCompra))
        ? 'A validade não pode ser antes da compra'
        : null;
  }

  static DateTime _dia(DateTime data) =>
      DateTime(data.year, data.month, data.day);
}

/// Uma compra para o estoque: data e produtos.
class LancamentoEstoque {
  const LancamentoEstoque({required this.dataCompra, this.itens = const []});

  final DateTime dataCompra;
  final List<ItemLancamento> itens;

  int get totalUnidades =>
      itens.fold(0, (soma, item) => soma + item.quantidade);

  int get custoTotal => itens.fold(0, (soma, item) => soma + item.total);

  /// Um produto entra uma vez só por compra.
  bool contem(String produtoId) =>
      itens.any((item) => item.produto.id == produtoId);

  static const mensagemRepetido = 'Este produto já está na compra.';

  static String? validarData(DateTime data, {required DateTime hoje}) {
    final dia = DateTime(data.year, data.month, data.day);
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    return dia.isAfter(hojeSemHora)
        ? 'A data da compra não pode ser no futuro'
        : null;
  }
}
