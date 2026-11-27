import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/model/forma_pagamento.dart';
import 'package:sou_consultora/core/model/item_venda.dart';
import 'package:sou_consultora/core/model/plano_parcelas.dart';

/// O pedido completo, pronto para `concluir_venda` / `editar_venda`.
class PedidoVenda {
  const PedidoVenda({
    required this.clienteId,
    required this.dataVenda,
    required this.itens,
    required this.parcelas,
    this.observacoes,
    this.entrada,
  });

  final String clienteId;
  final DateTime dataVenda;
  final List<ItemPedido> itens;
  final List<ParcelaPlano> parcelas;
  final String? observacoes;

  /// Forma da 1ª parcela já recebida (null = nada recebido ainda).
  final FormaPagamento? entrada;

  static int subtotalDe(List<ItemPedido> itens) =>
      itens.fold(0, (soma, i) => soma + i.bruto);

  static int descontosDe(List<ItemPedido> itens) =>
      itens.fold(0, (soma, i) => soma + i.desconto);

  static int totalDe(List<ItemPedido> itens) =>
      subtotalDe(itens) - descontosDe(itens);

  /// Parâmetros das funções do banco (sem `consultora_id`).
  Map<String, dynamic> paraGravar() => {
    'p_cliente_id': clienteId,
    'p_data_venda': ConversoresDto.textoData(dataVenda),
    'p_observacoes': observacoes,
    'p_itens': [for (final item in itens) item.paraGravar()],
    'p_parcelas': [for (final parcela in parcelas) parcela.paraGravar()],
    'p_pagamento': entrada == null ? null : {'forma': entrada!.valorBanco},
  };

  static String? validarDataVenda(DateTime data, {required DateTime hoje}) {
    final dia = DateTime(data.year, data.month, data.day);
    return dia.isAfter(DateTime(hoje.year, hoje.month, hoje.day))
        ? 'A data da venda não pode ser no futuro'
        : null;
  }
}
