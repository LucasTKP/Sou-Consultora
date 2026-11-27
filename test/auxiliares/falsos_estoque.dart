import 'package:sou_consultora/core/dto/lote_produto_dto.dart';
import 'package:sou_consultora/core/dto/saida_produto_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/item_lancamento.dart';
import 'package:sou_consultora/core/repository/repositorio_estoque.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/core/service/servico_estoque.dart';

import 'falsos_produtos.dart';

LoteProdutoDto loteDto(
  String id,
  String produtoId, {
  int numero = 1,
  int quantidade = 3,
  int? disponivel,
  int custo = 15500,
  DateTime? validade,
  String fornecedor = 'Natura',
  int saidas = 0,
}) => LoteProdutoDto(
  id: id,
  produtoId: produtoId,
  numeroLote: numero,
  quantidade: quantidade,
  quantidadeDisponivel: disponivel ?? quantidade,
  custoUnitario: custo,
  validade: validade,
  dataCompra: DateTime(2026, 11, 16),
  fornecedorNome: fornecedor,
  qtdSaidas: saidas,
);

SaidaProdutoDto saidaDto(String produtoId, String cliente, {int qtd = 1}) =>
    SaidaProdutoDto(
      itemVendaId: 'i-$cliente',
      produtoId: produtoId,
      vendaId: 'v-$cliente',
      dataVenda: DateTime(2026, 10, 22),
      clienteNome: cliente,
      quantidade: qtd,
      subtotal: 21990 * qtd,
    );

/// Service falso: guarda os lotes, cria lotes ao lançar e reflete no
/// [ServicoProdutosFalso] (para o saldo dos produtos acompanhar).
class ServicoEstoqueFalso implements ServicoEstoque {
  ServicoEstoqueFalso({
    List<LoteProdutoDto>? lotes,
    List<SaidaProdutoDto>? saidas,
    this.produtos,
  }) : lotes = lotes ?? [],
       saidas = saidas ?? [];

  List<LoteProdutoDto> lotes;
  List<SaidaProdutoDto> saidas;
  final ServicoProdutosFalso? produtos;
  bool falharRede = false;
  FalhaApp? falhaAoApagar;
  final List<LancamentoEstoque> lancados = [];
  final List<String> apagados = [];

  static const _falha = FalhaRede(
    'Sem conexão com a internet. Verifique e tente novamente.',
  );

  @override
  Future<Resultado<List<LoteProdutoDto>>> listarLotes(String produtoId) async {
    if (falharRede) return Erro(_falha);
    return Sucesso(
      lotes.where((l) => l.produtoId == produtoId).toList()
        ..sort((a, b) => b.numeroLote.compareTo(a.numeroLote)),
    );
  }

  @override
  Future<Resultado<List<SaidaProdutoDto>>> listarSaidas(
    String produtoId,
  ) async {
    if (falharRede) return Erro(_falha);
    return Sucesso(saidas.where((s) => s.produtoId == produtoId).toList());
  }

  @override
  Future<Resultado<int>> lancar(LancamentoEstoque lancamento) async {
    if (falharRede) return Erro(_falha);
    lancados.add(lancamento);
    for (final item in lancamento.itens) {
      final doProduto = lotes.where((l) => l.produtoId == item.produto.id);
      final numero = doProduto.isEmpty
          ? 1
          : doProduto.map((l) => l.numeroLote).reduce((a, b) => a > b ? a : b) +
                1;
      lotes.add(
        loteDto(
          'l-${item.produto.id}-$numero',
          item.produto.id,
          numero: numero,
          quantidade: item.quantidade,
          custo: item.custoUnitario,
          validade: item.validade,
        ),
      );
      _somarNoProduto(item.produto.id, item.quantidade);
    }
    return Sucesso(lancamento.itens.length);
  }

  @override
  Future<Resultado<void>> apagarLote(String loteId) async {
    if (falharRede) return Erro(_falha);
    if (falhaAoApagar case final falha?) return Erro(falha);
    final lote = lotes.firstWhere((l) => l.id == loteId);
    apagados.add(loteId);
    lotes = lotes.where((l) => l.id != loteId).toList();
    _somarNoProduto(lote.produtoId, -lote.quantidadeDisponivel);
    return const Sucesso(null);
  }

  void _somarNoProduto(String produtoId, int quantidade) {
    final servico = produtos;
    if (servico == null) return;
    servico.resumos = [
      for (final p in servico.resumos)
        p.id == produtoId
            ? produtoDto(
                p.id,
                p.nome,
                precoVenda: p.precoVenda,
                fornecedorId: p.fornecedorId,
                fornecedorNome: p.fornecedorNome,
                qtdDisponivel: p.qtdDisponivel + quantidade,
              )
            : p,
    ];
  }
}

RepositorioEstoque repositorioEstoqueDeTeste(
  ServicoEstoqueFalso servico,
  RepositorioProdutos produtos,
) => RepositorioEstoque(servico: servico, produtos: produtos);
