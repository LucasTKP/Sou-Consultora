/// Produto ou serviço.
enum TipoItem { produto, servico }

/// Um item já gravado numa venda (view `itens_vendas`). Valores em centavos.
class ItemVendido {
  const ItemVendido({
    required this.id,
    required this.vendaId,
    required this.tipo,
    required this.catalogoId,
    required this.nome,
    required this.quantidade,
    required this.precoUnitario,
    required this.desconto,
    required this.subtotal,
    required this.baixarEstoque,
    this.caminhoFoto,
    this.urlFoto,
    this.categoriaServico,
  });

  final String id;
  final String vendaId;
  final TipoItem tipo;

  /// Id do produto ou do serviço.
  final String catalogoId;
  final String nome;
  final int quantidade;
  final int precoUnitario;
  final int desconto;
  final int subtotal;
  final bool baixarEstoque;
  final String? caminhoFoto;
  final String? urlFoto;
  final String? categoriaServico;

  ItemVendido comUrl(String? url) => ItemVendido(
    id: id,
    vendaId: vendaId,
    tipo: tipo,
    catalogoId: catalogoId,
    nome: nome,
    quantidade: quantidade,
    precoUnitario: precoUnitario,
    desconto: desconto,
    subtotal: subtotal,
    baixarEstoque: baixarEstoque,
    caminhoFoto: caminhoFoto,
    urlFoto: url,
    categoriaServico: categoriaServico,
  );
}

/// Um item do pedido que está sendo montado (antes de gravar).
class ItemPedido {
  const ItemPedido({
    required this.tipo,
    required this.catalogoId,
    required this.nome,
    required this.precoUnitario,
    required this.quantidade,
    this.desconto = 0,
    this.baixarEstoque = true,
    this.saldoEstoque,
    this.urlFoto,
    this.categoriaServico,
  });

  final TipoItem tipo;
  final String catalogoId;
  final String nome;

  /// Do catálogo (não muda na venda).
  final int precoUnitario;
  final int quantidade;
  final int desconto;

  /// Só produto; serviço nunca baixa.
  final bool baixarEstoque;

  /// Unidades disponíveis do produto (null para serviço).
  final int? saldoEstoque;
  final String? urlFoto;
  final String? categoriaServico;

  int get bruto => precoUnitario * quantidade;

  int get subtotal => bruto - desconto;

  /// Chave do item no pedido (um produto ou serviço entra uma vez só).
  String get chave => '${tipo.name}:$catalogoId';

  bool get baixa => tipo == TipoItem.produto && baixarEstoque;

  Map<String, dynamic> paraGravar() => {
    if (tipo == TipoItem.produto) 'produto_id': catalogoId,
    if (tipo == TipoItem.servico) 'servico_id': catalogoId,
    'quantidade': quantidade,
    'desconto': desconto / 100,
    'baixar_estoque': baixa,
  };

  /// "Estoque insuficiente: 2 un disponíveis" quando a baixa passa do saldo.
  static String? validarQuantidade({
    required int quantidade,
    required bool baixa,
    int? saldo,
  }) {
    if (quantidade < 1) return 'Informe pelo menos 1 unidade';
    if (!baixa || saldo == null || quantidade <= saldo) return null;
    return 'Estoque insuficiente: $saldo un disponíveis';
  }

  static String? validarDesconto({required int desconto, required int bruto}) {
    if (desconto < 0) return 'O desconto não pode ser negativo';
    return desconto > bruto
        ? 'O desconto não pode passar do valor do item'
        : null;
  }
}
