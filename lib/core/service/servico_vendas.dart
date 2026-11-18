import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/dto/item_venda_dto.dart';
import 'package:sou_consultora/core/dto/resumo_parcela_dto.dart';
import 'package:sou_consultora/core/dto/resumo_venda_dto.dart';
import 'package:sou_consultora/core/erros/mapeador_falhas.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/pedido_venda.dart';

/// Views de vendas e as funções `concluir_venda`, `editar_venda` e
/// `cancelar_venda`. Nunca envia `consultora_id`: o banco usa a sessão.
class ServicoVendas {
  ServicoVendas({required this._api});

  final ApiSupabase _api;

  static const _vendas = 'resumo_vendas';
  static const _itens = 'itens_vendas';
  static const _parcelas = 'resumo_parcelas';

  Future<Resultado<List<ResumoVendaDto>>> listarResumos({String? clienteId}) {
    return executarComFalha(() async {
      final linhas = await _api.listar(
        _vendas,
        onde: {'cliente_id': ?clienteId},
      );
      return linhas.map(ResumoVendaDto.fromJson).toList();
    }, mensagemPadrao: 'Não foi possível carregar as vendas.');
  }

  Future<Resultado<ResumoVendaDto?>> buscarResumo(String id) {
    return executarComFalha(() async {
      final linha = await _api.buscarUm(_vendas, coluna: 'id', valor: id);
      return linha == null ? null : ResumoVendaDto.fromJson(linha);
    }, mensagemPadrao: 'Não foi possível carregar a venda.');
  }

  Future<Resultado<List<ItemVendaDto>>> listarItens(String vendaId) {
    return executarComFalha(() async {
      final linhas = await _api.listar(
        _itens,
        ordenarPor: 'nome',
        onde: {'venda_id': vendaId},
      );
      return linhas.map(ItemVendaDto.fromJson).toList();
    }, mensagemPadrao: 'Não foi possível carregar os itens da venda.');
  }

  /// Parcelas de uma venda, de uma cliente ou todas (nenhum filtro).
  Future<Resultado<List<ResumoParcelaDto>>> listarParcelas({
    String? vendaId,
    String? clienteId,
  }) {
    return executarComFalha(() async {
      final linhas = await _api.listar(
        _parcelas,
        ordenarPor: 'data_vencimento',
        onde: {'venda_id': ?vendaId, 'cliente_id': ?clienteId},
      );
      return linhas.map(ResumoParcelaDto.fromJson).toList()
        ..sort((a, b) => a.numeroParcela.compareTo(b.numeroParcela));
    }, mensagemPadrao: 'Não foi possível carregar as parcelas.');
  }

  /// Grava a venda (tudo ou nada) e devolve o id.
  Future<Resultado<String>> concluir(PedidoVenda pedido) {
    return executarComFalha(() async {
      final id = await _api.rpc(
        'concluir_venda',
        parametros: pedido.paraGravar(),
      );
      return id as String;
    }, mensagemPadrao: 'Não foi possível concluir a venda.');
  }

  /// Regrava a venda [id] (só sem pagamentos) e devolve o id.
  Future<Resultado<String>> editar(String id, PedidoVenda pedido) {
    return executarComFalha(() async {
      final gravado = await _api.rpc(
        'editar_venda',
        parametros: {'p_venda_id': id, ...pedido.paraGravar()},
      );
      return gravado as String;
    }, mensagemPadrao: 'Não foi possível salvar a venda.');
  }

  /// Apaga a venda e devolve o estoque.
  Future<Resultado<void>> cancelar(String id) {
    return executarComFalha(
      () => _api.rpc('cancelar_venda', parametros: {'p_venda_id': id}),
      mensagemPadrao: 'Não foi possível cancelar a venda.',
    );
  }

  /// URLs assinadas das fotos dos itens (caminho → URL).
  Future<Resultado<Map<String, String>>> urlsDasFotos(List<String> caminhos) {
    return executarComFalha(
      () => _api.urlsAssinadas('fotos', caminhos),
      mensagemPadrao: 'Não foi possível carregar as fotos.',
    );
  }
}
