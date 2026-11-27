import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/item_lancamento.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/core/repository/repositorio_estoque.dart';
import 'package:sou_consultora/core/service/servico_estoque.dart';

import '../../auxiliares/falsos_estoque.dart';
import '../../auxiliares/falsos_produtos.dart';

class _ApiFalsa implements ApiSupabase {
  bool semRede = false;
  String? funcao;
  Map<String, dynamic>? parametros;
  String? tabela;
  Map<String, Object>? filtro;

  @override
  Future<List<Map<String, dynamic>>> listar(
    String tabela, {
    String? ordenarPor,
    Map<String, Object> onde = const {},
  }) async {
    if (semRede) throw const SocketException('offline');
    this.tabela = tabela;
    filtro = onde;
    return [
      for (final numero in [1, 2])
        {
          'id': 'l$numero',
          'produto_id': 'p1',
          'numero_lote': numero,
          'quantidade': 3,
          'quantidade_disponivel': 3,
          'custo_unitario': 155,
          'validade': null,
          'data_compra': '2026-11-16',
          'fornecedor_nome': 'Natura',
          'qtd_saidas': 0,
        },
    ];
  }

  @override
  Future<dynamic> rpc(String funcao, {Map<String, dynamic>? parametros}) async {
    if (semRede) throw const SocketException('offline');
    this.funcao = funcao;
    this.parametros = parametros;
    return funcao == 'lancar_estoque' ? 1 : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ResumoProduto _produto() => produtoDto('p1', 'Kit Lily').paraModel();

LancamentoEstoque _lancamento() => LancamentoEstoque(
  dataCompra: DateTime(2026, 11, 16),
  itens: [
    ItemLancamento(produto: _produto(), quantidade: 3, custoUnitario: 15500),
  ],
);

void main() {
  late _ApiFalsa api;
  late ServicoEstoque servico;

  setUp(() {
    api = _ApiFalsa();
    servico = ServicoEstoque(api: api);
  });

  test('lotes do produto pela view, do mais novo para o mais antigo', () async {
    final resultado = await servico.listarLotes('p1');

    expect(api.tabela, 'lotes_produtos');
    expect(api.filtro, {'produto_id': 'p1'});
    expect((resultado as Sucesso).valor.map((l) => l.numeroLote), [2, 1]);
  });

  test(
    'lançar chama a função com a data e os itens, sem consultora_id',
    () async {
      final resultado = await servico.lancar(_lancamento());

      expect((resultado as Sucesso).valor, 1);
      expect(api.funcao, 'lancar_estoque');
      expect(api.parametros, {
        'p_data_compra': '2026-11-16',
        'p_itens': [
          {
            'produto_id': 'p1',
            'quantidade': 3,
            'custo_unitario': 155.0,
            'validade': null,
          },
        ],
      });
    },
  );

  test('apagar lote chama a função', () async {
    await servico.apagarLote('l1');

    expect(api.funcao, 'apagar_lote');
    expect(api.parametros, {'p_lote_id': 'l1'});
  });

  test('sem rede vira FalhaRede', () async {
    api.semRede = true;

    final resultado = await servico.lancar(_lancamento());

    expect((resultado as Erro).falha, isA<FalhaRede>());
  });

  group('RepositorioEstoque', () {
    test('lançar recarrega os produtos só em sucesso', () async {
      final produtos = ServicoProdutosFalso(
        resumos: [produtoDto('p1', 'Kit Lily')],
      );
      final estoque = ServicoEstoqueFalso(produtos: produtos);
      final repositorioProdutos = repositorioProdutosDeTeste(produtos);
      final repositorio = RepositorioEstoque(
        servico: estoque,
        produtos: repositorioProdutos,
      );

      await repositorio.lancar(_lancamento());
      expect(produtos.chamadas.where((c) => c == 'listar').length, 1);
      expect(repositorioProdutos.lista!.single.qtdDisponivel, 3);

      estoque.falharRede = true;
      final falhou = await repositorio.lancar(_lancamento());
      expect(falhou, isA<Erro<int>>());
      expect(produtos.chamadas.where((c) => c == 'listar').length, 1);
    });
  });
}
