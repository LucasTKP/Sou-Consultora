import 'package:sou_consultora/core/dto/item_venda_dto.dart';
import 'package:sou_consultora/core/dto/resumo_parcela_dto.dart';
import 'package:sou_consultora/core/dto/resumo_venda_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/pedido_venda.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/core/service/servico_vendas.dart';

import 'falsos_clientes.dart';

ResumoVendaDto vendaDto(
  String id, {
  int codigo = 1,
  String clienteId = 'c1',
  String cliente = 'Mariana Souza',
  int total = 24000,
  int pago = 0,
  int atrasado = 0,
  bool temPagamento = false,
  DateTime? data,
  String itens = 'Kit Lily',
  int qtdItens = 1,
}) => ResumoVendaDto(
  id: id,
  codigo: codigo,
  clienteId: clienteId,
  clienteNome: cliente,
  clienteWhatsapp: '11987654321',
  dataVenda: data ?? DateTime.now(),
  subtotal: total,
  totalDescontos: 0,
  total: total,
  qtdItens: qtdItens,
  qtdUnidades: qtdItens,
  nomesItens: itens,
  primeiroItem: itens.split(' | ').first,
  qtdParcelas: 1,
  qtdParcelasPagas: pago >= total ? 1 : 0,
  valorPago: pago,
  saldo: total - pago,
  valorAtrasado: atrasado,
  temPagamento: temPagamento || pago > 0,
);

ItemVendaDto itemDto(
  String vendaId,
  String nome, {
  String? produtoId = 'p1',
  String? servicoId,
  int preco = 24000,
  int quantidade = 1,
  int desconto = 0,
}) => ItemVendaDto(
  id: 'i-$vendaId-$nome',
  vendaId: vendaId,
  produtoId: servicoId == null ? produtoId : null,
  servicoId: servicoId,
  nome: nome,
  quantidade: quantidade,
  precoUnitario: preco,
  desconto: desconto,
  subtotal: preco * quantidade - desconto,
  baixarEstoque: servicoId == null,
);

ResumoParcelaDto parcelaDto(
  String id,
  String vendaId, {
  int numero = 1,
  int qtd = 1,
  int valor = 24000,
  int pago = 0,
  DateTime? vencimento,
  String clienteId = 'c1',
  String cliente = 'Mariana Souza',
  int codigo = 1,
  String itens = 'Kit Lily',
}) => ResumoParcelaDto(
  id: id,
  vendaId: vendaId,
  numeroParcela: numero,
  valor: valor,
  dataVencimento: vencimento ?? DateTime.now().add(const Duration(days: 10)),
  valorPago: pago,
  qtdPagamentos: pago > 0 ? 1 : 0,
  ultimoPagamento: pago > 0 ? DateTime.now() : null,
  vendaCodigo: codigo,
  dataVenda: DateTime.now(),
  vendaTotal: valor * qtd,
  qtdParcelas: qtd,
  clienteId: clienteId,
  clienteNome: cliente,
  clienteWhatsapp: '11987654321',
  nomesItens: itens,
);

/// Service falso em memória para Vendas.
class ServicoVendasFalso implements ServicoVendas {
  ServicoVendasFalso({
    List<ResumoVendaDto>? vendas,
    List<ItemVendaDto>? itens,
    List<ResumoParcelaDto>? parcelas,
  }) : vendas = vendas ?? [],
       itens = itens ?? [],
       parcelas = parcelas ?? [];

  List<ResumoVendaDto> vendas;
  List<ItemVendaDto> itens;
  List<ResumoParcelaDto> parcelas;
  bool falharRede = false;
  FalhaApp? falhaAoGravar;
  final List<PedidoVenda> concluidos = [];
  final List<({String id, PedidoVenda pedido})> editados = [];
  final List<String> cancelados = [];
  int _contador = 0;

  static const _falha = FalhaRede(
    'Sem conexão com a internet. Verifique e tente novamente.',
  );

  @override
  Future<Resultado<List<ResumoVendaDto>>> listarResumos({
    String? clienteId,
  }) async {
    if (falharRede) return Erro(_falha);
    return Sucesso([
      for (final v in vendas)
        if (clienteId == null || v.clienteId == clienteId) v,
    ]);
  }

  @override
  Future<Resultado<ResumoVendaDto?>> buscarResumo(String id) async {
    if (falharRede) return Erro(_falha);
    return Sucesso(vendas.where((v) => v.id == id).firstOrNull);
  }

  @override
  Future<Resultado<List<ItemVendaDto>>> listarItens(String vendaId) async {
    if (falharRede) return Erro(_falha);
    return Sucesso(itens.where((i) => i.vendaId == vendaId).toList());
  }

  @override
  Future<Resultado<List<ResumoParcelaDto>>> listarParcelas({
    String? vendaId,
    String? clienteId,
  }) async {
    if (falharRede) return Erro(_falha);
    return Sucesso([
      for (final p in parcelas)
        if ((vendaId == null || p.vendaId == vendaId) &&
            (clienteId == null || p.clienteId == clienteId))
          p,
    ]);
  }

  @override
  Future<Resultado<ResumoParcelaDto?>> buscarParcela(String id) async {
    if (falharRede) return Erro(_falha);
    return Sucesso(parcelas.where((p) => p.id == id).firstOrNull);
  }

  @override
  Future<Resultado<String>> concluir(PedidoVenda pedido) async {
    if (falharRede) return Erro(_falha);
    if (falhaAoGravar case final falha?) return Erro(falha);
    concluidos.add(pedido);
    final id = 'nova-${++_contador}';
    vendas = [
      ...vendas,
      vendaDto(
        id,
        codigo: 100 + _contador,
        clienteId: pedido.clienteId,
        total: PedidoVenda.totalDe(pedido.itens),
      ),
    ];
    return Sucesso(id);
  }

  @override
  Future<Resultado<String>> editar(String id, PedidoVenda pedido) async {
    if (falharRede) return Erro(_falha);
    editados.add((id: id, pedido: pedido));
    return Sucesso(id);
  }

  @override
  Future<Resultado<void>> cancelar(String id) async {
    if (falharRede) return Erro(_falha);
    cancelados.add(id);
    vendas = vendas.where((v) => v.id != id).toList();
    return const Sucesso(null);
  }

  @override
  Future<Resultado<Map<String, String>>> urlsDasFotos(
    List<String> caminhos,
  ) async => Sucesso({for (final c in caminhos) c: 'https://assinada/$c'});
}

RepositorioVendas repositorioVendasDeTeste(
  ServicoVendasFalso servico, {
  required RepositorioProdutos produtos,
  required RepositorioClientes clientes,
  ServicoWhatsappFalso? whatsapp,
}) => RepositorioVendas(
  servico: servico,
  produtos: produtos,
  clientes: clientes,
  whatsapp: whatsapp ?? ServicoWhatsappFalso(),
);
