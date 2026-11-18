// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

/// Itens fixos da barra inferior, na ordem em que aparecem.
enum ItemBarra { produtos, clientes, inicio, vendas, financeiro }

/// Módulo principal do app (tela inicial de cada fluxo de `fluxos.md`).
class ModuloApp {
  const ModuloApp({
    required this.rota,
    required this.titulo,
    required this.icone,
    this.itemBarra,
  });

  final String rota;
  final String titulo;
  final IconData icone;

  /// Item da barra inferior que fica ativo neste módulo (null = nenhum).
  final ItemBarra? itemBarra;
}

/// Rotas do app. [modulos] são as telas principais (dentro da casca, com a barra).
/// Sub-rotas (ex.: `/clientes/novo`) são criadas por cada fase.
abstract final class RotasApp {
  static const login = '/login';
  static const carregando = '/carregando';
  static const cadastro = '/cadastro';
  static const inicio = '/inicio';
  static const produtos = '/produtos';
  static const clientes = '/clientes';
  static const vendas = '/vendas';
  static const financeiro = '/financeiro';
  static const servicos = '/servicos';
  static const fornecedores = '/fornecedores';
  static const aReceber = '/a-receber';
  static const aPagar = '/a-pagar';

  /// Perfil abre por cima das telas principais (sem a barra).
  static const perfil = '/perfil';
  static const editarPerfil = '/perfil/editar';

  // Clientes: lista na casca; o resto abre por cima.
  static const novoCliente = '/clientes/novo';
  static String detalhesCliente(String id) => '/clientes/$id';
  static String dadosCliente(String id) => '/clientes/$id/dados';
  static String editarCliente(String id) => '/clientes/$id/editar';
  static String comprasCliente(String id) => '/clientes/$id/compras';

  // Vendas: lista na casca (item da barra); o resto abre por cima.
  static const novaVenda = '/vendas/nova';

  /// Nova venda com a cliente já escolhida.
  static String novaVendaPara(String idCliente) =>
      '/vendas/nova?cliente=$idCliente';
  static String detalhesVenda(String id) => '/vendas/$id';
  static String editarVenda(String id) => '/vendas/$id/editar';

  // A receber: parcelas e comprovantes abrem por cima.
  static String detalhesParcela(String id) => '/a-receber/parcelas/$id';

  /// Comprovante do pagamento [idPagamento] da parcela; sem ele, do último.
  static String comprovanteParcela(String idParcela, {String? idPagamento}) =>
      idPagamento == null
      ? '/a-receber/parcelas/$idParcela/comprovante'
      : '/a-receber/parcelas/$idParcela/comprovante?pagamento=$idPagamento';

  // A pagar: lista na casca (pelo menu); o resto abre por cima.
  /// Novo boleto; com [fornecedorId], a marca já vem escolhida.
  static String novoBoleto({String? fornecedorId}) => fornecedorId == null
      ? '/a-pagar/novo'
      : '/a-pagar/novo?fornecedor=$fornecedorId';
  static String detalhesBoleto(String id) => '/a-pagar/$id';
  static String editarBoleto(String id) => '/a-pagar/$id/editar';

  /// A pagar só com os boletos da marca (aberta por Fornecedores, por cima).
  static String boletosDoFornecedor(String fornecedorId) =>
      '/a-pagar/fornecedor/$fornecedorId';

  // Fornecedores: lista na casca (pelo menu); o resto abre por cima.
  static const novoFornecedor = '/fornecedores/novo';
  static String detalhesFornecedor(String id) => '/fornecedores/$id';
  static String editarFornecedor(String id) => '/fornecedores/$id/editar';

  // Produtos: lista na casca (item da barra); o resto abre por cima.
  static const novoProduto = '/produtos/novo';
  static String detalhesProduto(String id) => '/produtos/$id';
  static String editarProduto(String id) => '/produtos/$id/editar';

  /// Lançar estoque; com [produtoId], a folha de item já abre com ele escolhido.
  static String lancarEstoque({String? produtoId}) => produtoId == null
      ? '/produtos/lancar-estoque'
      : '/produtos/lancar-estoque?produto=$produtoId';

  // Serviços: lista na casca (pelo menu); o resto abre por cima.
  static const novoServico = '/servicos/novo';
  static String detalhesServico(String id) => '/servicos/$id';
  static String editarServico(String id) => '/servicos/$id/editar';

  static const modulos = <ModuloApp>[
    ModuloApp(
      rota: inicio,
      titulo: 'Início',
      icone: Icons.home_rounded,
      itemBarra: ItemBarra.inicio,
    ),
    ModuloApp(
      rota: vendas,
      titulo: 'Vendas',
      icone: Icons.shopping_bag_outlined,
      itemBarra: ItemBarra.vendas,
    ),
    ModuloApp(
      rota: clientes,
      titulo: 'Clientes',
      icone: Icons.people_alt_outlined,
      itemBarra: ItemBarra.clientes,
    ),
    ModuloApp(
      rota: produtos,
      titulo: 'Produtos',
      icone: Icons.inventory_2_outlined,
      itemBarra: ItemBarra.produtos,
    ),
    ModuloApp(rota: servicos, titulo: 'Serviços', icone: Icons.spa_outlined),
    ModuloApp(
      rota: fornecedores,
      titulo: 'Fornecedores',
      icone: Icons.local_shipping_outlined,
    ),
    ModuloApp(
      rota: aReceber,
      titulo: 'A Receber',
      icone: Icons.payments_outlined,
    ),
    ModuloApp(
      rota: aPagar,
      titulo: 'A Pagar',
      icone: Icons.receipt_long_outlined,
    ),
    ModuloApp(
      rota: financeiro,
      titulo: 'Financeiro',
      icone: Icons.account_balance_wallet_outlined,
      itemBarra: ItemBarra.financeiro,
    ),
  ];

  /// Rota principal do item da barra.
  static String rotaDoItem(ItemBarra item) =>
      modulos.firstWhere((modulo) => modulo.itemBarra == item).rota;

  /// Módulo dono do caminho (pelo primeiro segmento: `/clientes/123` → Clientes).
  static ModuloApp? moduloDe(String caminho) {
    final segmentos = Uri.parse(caminho).pathSegments;
    if (segmentos.isEmpty) return null;
    final raiz = '/${segmentos.first}';
    for (final modulo in modulos) {
      if (modulo.rota == raiz) return modulo;
    }
    return null;
  }

  /// Item da barra ativo para o caminho (null quando o módulo não está na barra).
  static ItemBarra? itemAtivo(String caminho) => moduloDe(caminho)?.itemBarra;
}
