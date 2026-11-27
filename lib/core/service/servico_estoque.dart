import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/dto/lote_produto_dto.dart';
import 'package:sou_consultora/core/dto/saida_produto_dto.dart';
import 'package:sou_consultora/core/erros/mapeador_falhas.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/item_lancamento.dart';

/// Lotes e saídas por produto (views) e as funções `lancar_estoque` e
/// `apagar_lote`. Nunca envia `consultora_id`: o banco usa a sessão.
class ServicoEstoque {
  ServicoEstoque({required this._api});

  final ApiSupabase _api;

  /// Lotes do produto, do mais novo para o mais antigo.
  Future<Resultado<List<LoteProdutoDto>>> listarLotes(String produtoId) {
    return executarComFalha(() async {
      final linhas = await _api.listar(
        'lotes_produtos',
        onde: {'produto_id': produtoId},
      );
      return linhas.map(LoteProdutoDto.fromJson).toList()
        ..sort((a, b) => b.numeroLote.compareTo(a.numeroLote));
    }, mensagemPadrao: 'Não foi possível carregar o estoque.');
  }

  /// Vendas que consumiram o produto, da mais recente para a mais antiga.
  Future<Resultado<List<SaidaProdutoDto>>> listarSaidas(String produtoId) {
    return executarComFalha(() async {
      final linhas = await _api.listar(
        'saidas_produtos',
        onde: {'produto_id': produtoId},
      );
      return linhas.map(SaidaProdutoDto.fromJson).toList()
        ..sort((a, b) => b.dataVenda.compareTo(a.dataVenda));
    }, mensagemPadrao: 'Não foi possível carregar as saídas.');
  }

  /// Grava a compra (tudo ou nada) e devolve quantos lotes foram criados.
  Future<Resultado<int>> lancar(LancamentoEstoque lancamento) {
    return executarComFalha(() async {
      final gravados = await _api.rpc(
        'lancar_estoque',
        parametros: {
          'p_data_compra': ConversoresDto.textoData(lancamento.dataCompra),
          'p_itens': [for (final item in lancamento.itens) item.paraGravar()],
        },
      );
      return gravados as int;
    }, mensagemPadrao: 'Não foi possível salvar o lançamento.');
  }

  /// Apaga um lote que nunca teve saída.
  Future<Resultado<void>> apagarLote(String loteId) {
    return executarComFalha(
      () => _api.rpc('apagar_lote', parametros: {'p_lote_id': loteId}),
      mensagemPadrao: 'Não foi possível apagar o lote.',
    );
  }
}
