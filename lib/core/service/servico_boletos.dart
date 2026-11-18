import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/dto/boleto_dto.dart';
import 'package:sou_consultora/core/dto/conversores_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/mapeador_falhas.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/arquivo_comprovante.dart';
import 'package:sou_consultora/core/model/boleto.dart';

/// Acesso a `boletos`, à view `resumo_boletos` e aos comprovantes no bucket
/// `comprovantes`. Nunca envia `consultora_id`: o banco preenche e o RLS confere.
class ServicoBoletos {
  ServicoBoletos({required this._api, DateTime Function()? agora})
    : _agora = agora ?? DateTime.now;

  final ApiSupabase _api;
  final DateTime Function() _agora;

  static const _tabela = 'boletos';
  static const _view = 'resumo_boletos';
  static const _bucket = 'comprovantes';

  Future<Resultado<List<BoletoDto>>> listar() {
    return executarComFalha(() async {
      final linhas = await _api.listar(_view, ordenarPor: 'data_vencimento');
      return linhas.map(BoletoDto.fromJson).toList();
    }, mensagemPadrao: 'Não foi possível carregar os boletos.');
  }

  /// Um boleto (Sucesso(null) se não existir ou não for da consultora).
  Future<Resultado<BoletoDto?>> buscar(String id) {
    return executarComFalha(() async {
      final linha = await _api.buscarUm(_view, coluna: 'id', valor: id);
      return linha == null ? null : BoletoDto.fromJson(linha);
    }, mensagemPadrao: 'Não foi possível carregar o boleto.');
  }

  /// Lança o boleto e devolve o id.
  Future<Resultado<String>> criar(PedidoBoleto pedido) {
    return executarComFalha(() async {
      final linha = await _api.inserir(_tabela, _dados(pedido));
      return linha['id'] as String;
    }, mensagemPadrao: 'Não foi possível salvar o boleto.');
  }

  Future<Resultado<String>> atualizar(String id, PedidoBoleto pedido) {
    return _gravar(id, _dados(pedido), 'Não foi possível salvar o boleto.');
  }

  /// Quita o boleto inteiro na [data] (o banco recusa data futura).
  Future<Resultado<String>> pagar(String id, DateTime data) {
    return _gravar(id, {
      'data_pagamento': ConversoresDto.textoData(data),
    }, 'Não foi possível confirmar o pagamento.');
  }

  Future<Resultado<String>> desfazerPagamento(String id) {
    return _gravar(id, {
      'data_pagamento': null,
    }, 'Não foi possível desfazer o pagamento.');
  }

  /// Guarda o caminho do comprovante no boleto (null = sem comprovante).
  Future<Resultado<String>> gravarComprovante(String id, String? caminho) {
    return _gravar(id, {
      'comprovante_url': caminho,
    }, 'Não foi possível salvar o comprovante.');
  }

  /// Apaga o boleto. Sucesso(false) quando ele não existe (ou não é da
  /// consultora: o RLS esconde).
  Future<Resultado<bool>> excluir(String id) {
    return executarComFalha(() async {
      final apagadas = await _api.excluir(_tabela, coluna: 'id', valor: id);
      return apagadas > 0;
    }, mensagemPadrao: 'Não foi possível excluir o boleto.');
  }

  /// Envia para `comprovantes/<id>/boletos/<boleto>/<momento>.<ext>` e
  /// devolve o caminho.
  Future<Resultado<String>> enviarComprovante(
    String idBoleto,
    ArquivoComprovante arquivo,
  ) async {
    final id = _api.idUsuario;
    if (id == null) {
      return Erro(
        const FalhaAutenticacao('Sua sessão terminou. Entre novamente.'),
      );
    }
    return executarComFalha(() async {
      final momento = _agora().millisecondsSinceEpoch;
      final caminho = '$id/boletos/$idBoleto/$momento.${arquivo.tipo.extensao}';
      await _api.enviarArquivo(
        _bucket,
        caminho,
        arquivo.bytes,
        tipoConteudo: arquivo.tipo.tipoConteudo,
      );
      return caminho;
    }, mensagemPadrao: 'Não foi possível enviar o comprovante.');
  }

  Future<Resultado<void>> removerComprovante(String caminho) {
    return executarComFalha(
      () => _api.removerArquivos(_bucket, [caminho]),
      mensagemPadrao: 'Não foi possível remover o comprovante.',
    );
  }

  /// Link temporário (5 minutos) para abrir o comprovante.
  Future<Resultado<String>> linkComprovante(String caminho) {
    return executarComFalha(
      () => _api.urlAssinada(
        _bucket,
        caminho,
        validade: const Duration(minutes: 5),
      ),
      mensagemPadrao: 'Não foi possível abrir o comprovante.',
    );
  }

  Future<Resultado<String>> _gravar(
    String id,
    Map<String, dynamic> dados,
    String mensagemPadrao,
  ) {
    return executarComFalha(() async {
      final linha = await _api.atualizar(
        _tabela,
        dados,
        coluna: 'id',
        valor: id,
      );
      return linha['id'] as String;
    }, mensagemPadrao: mensagemPadrao);
  }

  static Map<String, dynamic> _dados(PedidoBoleto pedido) => {
    'fornecedor_id': pedido.fornecedorId,
    'valor': pedido.valor / 100,
    'data_vencimento': ConversoresDto.textoData(pedido.vencimento),
    'forma_pagamento': pedido.forma?.valorBanco,
    'observacoes': pedido.observacoes,
  };
}
