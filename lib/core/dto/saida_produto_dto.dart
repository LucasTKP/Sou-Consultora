import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/model/saida_produto.dart';

/// Espelho da view `saidas_produtos`.
class SaidaProdutoDto {
  const SaidaProdutoDto({
    required this.itemVendaId,
    required this.produtoId,
    required this.vendaId,
    required this.dataVenda,
    required this.clienteNome,
    required this.quantidade,
    required this.subtotal,
  });

  factory SaidaProdutoDto.fromJson(Map<String, dynamic> json) {
    return SaidaProdutoDto(
      itemVendaId: json['item_venda_id'] as String,
      produtoId: json['produto_id'] as String,
      vendaId: json['venda_id'] as String,
      dataVenda: ConversoresDto.momento(json['data_venda'])!,
      clienteNome: json['cliente_nome'] as String,
      quantidade: json['quantidade'] as int,
      subtotal: ConversoresDto.centavos(json['subtotal']),
    );
  }

  final String itemVendaId;
  final String produtoId;
  final String vendaId;
  final DateTime dataVenda;
  final String clienteNome;
  final int quantidade;

  /// Centavos.
  final int subtotal;

  SaidaProduto paraModel() => SaidaProduto(
    itemVendaId: itemVendaId,
    vendaId: vendaId,
    dataVenda: dataVenda,
    clienteNome: clienteNome,
    quantidade: quantidade,
    valor: subtotal,
  );
}
