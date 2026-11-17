import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/model/lote_produto.dart';

/// Espelho da view `lotes_produtos`.
class LoteProdutoDto {
  const LoteProdutoDto({
    required this.id,
    required this.produtoId,
    required this.numeroLote,
    required this.quantidade,
    required this.quantidadeDisponivel,
    required this.custoUnitario,
    required this.dataCompra,
    required this.fornecedorNome,
    required this.qtdSaidas,
    this.validade,
  });

  factory LoteProdutoDto.fromJson(Map<String, dynamic> json) {
    return LoteProdutoDto(
      id: json['id'] as String,
      produtoId: json['produto_id'] as String,
      numeroLote: json['numero_lote'] as int,
      quantidade: json['quantidade'] as int,
      quantidadeDisponivel: json['quantidade_disponivel'] as int,
      custoUnitario: ConversoresDto.centavos(json['custo_unitario']),
      validade: ConversoresDto.data(json['validade']),
      dataCompra: ConversoresDto.data(json['data_compra'])!,
      fornecedorNome: json['fornecedor_nome'] as String,
      qtdSaidas: json['qtd_saidas'] as int,
    );
  }

  final String id;
  final String produtoId;
  final int numeroLote;
  final int quantidade;
  final int quantidadeDisponivel;

  /// Centavos.
  final int custoUnitario;
  final DateTime? validade;
  final DateTime dataCompra;
  final String fornecedorNome;
  final int qtdSaidas;

  LoteProduto paraModel() => LoteProduto(
    id: id,
    produtoId: produtoId,
    numero: numeroLote,
    quantidade: quantidade,
    disponivel: quantidadeDisponivel,
    custoUnitario: custoUnitario,
    validade: validade,
    dataCompra: dataCompra,
    fornecedorNome: fornecedorNome,
    qtdSaidas: qtdSaidas,
  );
}
