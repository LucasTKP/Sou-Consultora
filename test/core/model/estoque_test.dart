import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/dto/lote_produto_dto.dart';
import 'package:sou_consultora/core/dto/saida_produto_dto.dart';
import 'package:sou_consultora/core/model/item_lancamento.dart';
import 'package:sou_consultora/core/model/lote_produto.dart';
import 'package:sou_consultora/core/model/margem.dart';
import 'package:sou_consultora/core/model/resumo_estoque.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';

LoteProduto _lote({
  int numero = 1,
  int quantidade = 3,
  int disponivel = 3,
  int custo = 15500,
  int saidas = 0,
}) => LoteProduto(
  id: 'l$numero',
  produtoId: 'p1',
  numero: numero,
  quantidade: quantidade,
  disponivel: disponivel,
  custoUnitario: custo,
  dataCompra: DateTime(2026, 11, 16),
  fornecedorNome: 'O Boticário',
  qtdSaidas: saidas,
);

ResumoProduto _produto(String id) => ResumoProduto(
  id: id,
  nome: 'Produto $id',
  fornecedorId: 'm1',
  fornecedorNome: 'Natura',
  categoriaId: 'c1',
  categoriaNome: 'Perfumaria',
  precoVenda: 21990,
  criadoEm: DateTime(2026),
);

void main() {
  group('Margem', () {
    test('exemplo da tela: R\$ 64,90 (29,5%) excelente', () {
      final margem = Margem.calcular(precoVenda: 21990, custo: 15500);
      expect(margem.valor, 6490);
      expect(margem.porcentagem, closeTo(29.5, 0.05));
      expect(margem.faixa, FaixaMargem.excelente);
    });

    test('limites de 25%, 10% e 0%', () {
      FaixaMargem faixa(int custo) =>
          Margem.calcular(precoVenda: 10000, custo: custo).faixa;
      expect(faixa(7500), FaixaMargem.excelente);
      expect(faixa(7501), FaixaMargem.boa);
      expect(faixa(9000), FaixaMargem.boa);
      expect(faixa(9001), FaixaMargem.baixa);
      expect(faixa(10000), FaixaMargem.baixa);
      expect(faixa(10001), FaixaMargem.prejuizo);
      expect(FaixaMargem.prejuizo.rotulo, 'Prejuízo');
    });
  });

  group('ResumoEstoque', () {
    test('custo médio ponderado e valor em estoque (exemplo da spec)', () {
      final resumo = ResumoEstoque.dosLotes([
        _lote(numero: 1, quantidade: 2, disponivel: 1, custo: 12480),
        _lote(numero: 2, quantidade: 3, disponivel: 3, custo: 15500),
      ]);
      expect(resumo.saldo, 4);
      expect(resumo.custoMedio, 14745);
      expect(resumo.valorEmEstoque, 58980);
      expect(resumo.prontaEntrega, isTrue);
    });

    test('sem lotes tudo zero; lote esgotado não conta', () {
      expect(ResumoEstoque.dosLotes([]).custoMedio, 0);
      final resumo = ResumoEstoque.dosLotes([_lote(disponivel: 0)]);
      expect(resumo.saldo, 0);
      expect(resumo.valorEmEstoque, 0);
      expect(resumo.prontaEntrega, isFalse);
    });
  });

  group('LoteProduto', () {
    test('situação, textos e rótulo', () {
      final recebido = _lote(numero: 2);
      expect(recebido.rotulo, '#02');
      expect(recebido.textoSituacao, '3 un recebidas');
      expect(recebido.textoSaldo, '3 disponíveis');
      expect(recebido.totalPago, 46500);

      final parcial = _lote(quantidade: 2, disponivel: 1, saidas: 1);
      expect(parcial.situacao, SituacaoLote.restante);
      expect(parcial.textoSituacao, '1 un restante');
      expect(parcial.textoSaldo, '1 de 2 vendida');

      final esgotado = _lote(quantidade: 2, disponivel: 0, saidas: 2);
      expect(esgotado.textoSituacao, 'Esgotado');
      expect(esgotado.textoSaldo, '2 de 2 vendidas');
    });

    test('só lote sem saída pode ser apagado', () {
      expect(_lote().podeApagar, isTrue);
      expect(_lote(disponivel: 2, saidas: 1).podeApagar, isFalse);
    });
  });

  group('Lançamento', () {
    test('totais, produto repetido e formato para gravar', () {
      final lancamento = LancamentoEstoque(
        dataCompra: DateTime(2026, 11, 16),
        itens: [
          ItemLancamento(
            produto: _produto('p1'),
            quantidade: 3,
            custoUnitario: 15500,
            validade: DateTime(2027, 3, 15),
          ),
          ItemLancamento(
            produto: _produto('p2'),
            quantidade: 10,
            custoUnitario: 2850,
          ),
        ],
      );
      expect(lancamento.totalUnidades, 13);
      expect(lancamento.custoTotal, 75000);
      expect(lancamento.contem('p1'), isTrue);
      expect(lancamento.contem('p3'), isFalse);
      expect(lancamento.itens.first.paraGravar(), {
        'produto_id': 'p1',
        'quantidade': 3,
        'custo_unitario': 155.0,
        'validade': '2027-03-15',
      });
      expect(lancamento.itens.last.paraGravar()['validade'], isNull);
    });

    test('validações', () {
      final compra = DateTime(2026, 11, 16);
      expect(ItemLancamento.validarProduto(null), 'Escolha o produto');
      expect(ItemLancamento.validarQuantidade(0), isNotNull);
      expect(ItemLancamento.validarCusto(null), 'Informe o custo unitário');
      expect(ItemLancamento.validarCusto(0), 'Informe o custo unitário');
      expect(ItemLancamento.validarCusto(100), isNull);
      expect(ItemLancamento.validarValidade(null, compra), isNull);
      expect(
        ItemLancamento.validarValidade(DateTime(2026, 11, 15), compra),
        isNotNull,
      );
      expect(
        ItemLancamento.validarValidade(DateTime(2026, 11, 16, 8), compra),
        isNull,
      );
      expect(
        LancamentoEstoque.validarData(
          DateTime(2026, 11, 18),
          hoje: DateTime(2026, 11, 17, 23),
        ),
        isNotNull,
      );
      expect(
        LancamentoEstoque.validarData(
          DateTime(2026, 11, 17),
          hoje: DateTime(2026, 11, 17, 1),
        ),
        isNull,
      );
    });
  });

  group('DTOs', () {
    test('LoteProdutoDto e SaidaProdutoDto', () {
      final lote = LoteProdutoDto.fromJson({
        'id': 'l1',
        'produto_id': 'p1',
        'numero_lote': 2,
        'quantidade': 3,
        'quantidade_disponivel': 3,
        'custo_unitario': '155.00',
        'validade': null,
        'data_compra': '2026-11-16',
        'fornecedor_nome': 'O Boticário',
        'qtd_saidas': 0,
        'created_at': '2026-11-16T12:00:00Z',
      }).paraModel();
      expect(lote.custoUnitario, 15500);
      expect(lote.dataCompra, DateTime(2026, 11, 16));
      expect(lote.validade, isNull);

      final saida = SaidaProdutoDto.fromJson({
        'item_venda_id': 'i1',
        'produto_id': 'p1',
        'venda_id': 'v1',
        'data_venda': '2026-10-22T15:00:00Z',
        'cliente_nome': 'Beatriz Oliveira',
        'quantidade': 1,
        'subtotal': 219.9,
      }).paraModel();
      expect(saida.valor, 21990);
      expect(saida.clienteNome, 'Beatriz Oliveira');
    });
  });
}
