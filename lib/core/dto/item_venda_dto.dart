import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/model/item_venda.dart';

/// Espelho da view `itens_vendas`.
class ItemVendaDto {
  const ItemVendaDto({
    required this.id,
    required this.vendaId,
    required this.nome,
    required this.quantidade,
    required this.precoUnitario,
    required this.desconto,
    required this.subtotal,
    required this.baixarEstoque,
    this.produtoId,
    this.servicoId,
    this.fotoUrl,
    this.categoriaServico,
  });

  factory ItemVendaDto.fromJson(Map<String, dynamic> json) {
    return ItemVendaDto(
      id: json['id'] as String,
      vendaId: json['venda_id'] as String,
      produtoId: json['produto_id'] as String?,
      servicoId: json['servico_id'] as String?,
      nome: json['nome'] as String,
      fotoUrl: json['foto_url'] as String?,
      categoriaServico: json['categoria_servico'] as String?,
      quantidade: json['quantidade'] as int,
      precoUnitario: ConversoresDto.centavos(json['preco_unitario']),
      desconto: ConversoresDto.centavos(json['desconto']),
      subtotal: ConversoresDto.centavos(json['subtotal']),
      baixarEstoque: json['baixar_estoque'] as bool,
    );
  }

  final String id;
  final String vendaId;

  /// Exatamente um dos dois (CHECK no banco).
  final String? produtoId;
  final String? servicoId;
  final String nome;

  /// Caminho no bucket `fotos`.
  final String? fotoUrl;
  final String? categoriaServico;
  final int quantidade;

  /// Centavos.
  final int precoUnitario;
  final int desconto;
  final int subtotal;
  final bool baixarEstoque;

  ItemVendido paraModel({String? urlFoto}) => ItemVendido(
    id: id,
    vendaId: vendaId,
    tipo: produtoId != null ? TipoItem.produto : TipoItem.servico,
    catalogoId: produtoId ?? servicoId!,
    nome: nome,
    quantidade: quantidade,
    precoUnitario: precoUnitario,
    desconto: desconto,
    subtotal: subtotal,
    baixarEstoque: baixarEstoque,
    caminhoFoto: fotoUrl,
    urlFoto: urlFoto,
    categoriaServico: categoriaServico,
  );
}
