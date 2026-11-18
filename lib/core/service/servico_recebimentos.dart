import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/dto/pagamento_dto.dart';
import 'package:sou_consultora/core/erros/mapeador_falhas.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/forma_pagamento.dart';

/// Pagamentos das parcelas (view `pagamentos_parcelas`) e a função
/// `registrar_pagamento`. As parcelas vêm do `ServicoVendas`.
class ServicoRecebimentos {
  ServicoRecebimentos({required this._api});

  final ApiSupabase _api;

  /// Pagamentos de uma venda, do mais recente para o mais antigo.
  Future<Resultado<List<PagamentoDto>>> listarPagamentos(String vendaId) {
    return executarComFalha(() async {
      final linhas = await _api.listar(
        'pagamentos_parcelas',
        onde: {'venda_id': vendaId},
      );
      return linhas.map(PagamentoDto.fromJson).toList()
        ..sort((a, b) => b.dataPagamento.compareTo(a.dataPagamento));
    }, mensagemPadrao: 'Não foi possível carregar os pagamentos.');
  }

  /// Todos os pagamentos da consultora (o Início soma os do mês).
  Future<Resultado<List<PagamentoDto>>> listarTodosPagamentos() {
    return executarComFalha(() async {
      final linhas = await _api.listar('pagamentos_parcelas');
      return linhas.map(PagamentoDto.fromJson).toList();
    }, mensagemPadrao: 'Não foi possível carregar os pagamentos.');
  }

  /// Grava o pagamento e devolve o id.
  Future<Resultado<String>> registrar({
    required String parcelaId,
    required int valorCentavos,
    required FormaPagamento forma,
    required DateTime data,
    String? observacao,
  }) {
    return executarComFalha(() async {
      final id = await _api.rpc(
        'registrar_pagamento',
        parametros: {
          'p_parcela_id': parcelaId,
          'p_valor': valorCentavos / 100,
          'p_forma': forma.valorBanco,
          'p_data': ConversoresDto.textoData(data),
          'p_observacao': observacao,
        },
      );
      return id as String;
    }, mensagemPadrao: 'Não foi possível registrar o pagamento.');
  }
}
