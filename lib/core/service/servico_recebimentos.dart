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

  /// Corrige um pagamento: valor, forma, data e observação.
  Future<Resultado<void>> editarPagamento({
    required String pagamentoId,
    required int valorCentavos,
    required FormaPagamento forma,
    required DateTime data,
    String? observacao,
  }) {
    return executarComFalha(
      () => _api.rpc(
        'editar_pagamento',
        parametros: {
          'p_pagamento_id': pagamentoId,
          'p_valor': valorCentavos / 100,
          'p_forma': forma.valorBanco,
          'p_data': ConversoresDto.textoData(data),
          'p_observacao': observacao,
        },
      ),
      mensagemPadrao: 'Não foi possível editar o pagamento.',
    );
  }

  /// Apaga um pagamento lançado por engano.
  Future<Resultado<void>> excluirPagamento(String pagamentoId) {
    return executarComFalha(
      () => _api.rpc(
        'excluir_pagamento',
        parametros: {'p_pagamento_id': pagamentoId},
      ),
      mensagemPadrao: 'Não foi possível excluir o pagamento.',
    );
  }

  /// Regrava valor e vencimento de todas as parcelas da venda. A soma tem
  /// que continuar igual ao total, e parcela com pagamento não muda.
  Future<Resultado<void>> editarParcelas({
    required String vendaId,
    required List<({String id, int valorCentavos, DateTime vencimento})>
    parcelas,
  }) {
    return executarComFalha(
      () => _api.rpc(
        'editar_parcelas',
        parametros: {
          'p_venda_id': vendaId,
          'p_parcelas': [
            for (final parcela in parcelas)
              {
                'id': parcela.id,
                'valor': parcela.valorCentavos / 100,
                'data_vencimento': ConversoresDto.textoData(parcela.vencimento),
              },
          ],
        },
      ),
      mensagemPadrao: 'Não foi possível salvar as parcelas.',
    );
  }
}
