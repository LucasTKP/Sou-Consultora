import 'dart:async';
import 'dart:typed_data';

import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/detalhe_parcela.dart';
import 'package:sou_consultora/core/model/forma_pagamento.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/core/service/servico_compartilhar.dart';
import 'package:sou_consultora/core/service/servico_recebimentos.dart';
import 'package:sou_consultora/core/service/servico_vendas.dart';

/// Parcelas a receber da consultora logada (A receber).
///
/// Guarda a lista e avisa em [mudancas]. Recarrega quando as vendas mudam e,
/// depois de registrar um pagamento, recarrega vendas e clientes também.
class RepositorioRecebimentos {
  RepositorioRecebimentos({
    required this._vendas,
    required this._recebimentos,
    required this._repositorioVendas,
    required this._clientes,
    required this._compartilhar,
    Stream<void>? sessaoEncerrada,
  }) {
    _assinaturaSessao = sessaoEncerrada?.listen((_) => limpar());
    _assinaturaVendas = _repositorioVendas.mudancas.listen((_) {
      if (_lista != null) carregar();
    });
  }

  final ServicoVendas _vendas;
  final ServicoRecebimentos _recebimentos;
  final RepositorioVendas _repositorioVendas;
  final RepositorioClientes _clientes;
  final ServicoCompartilhar _compartilhar;
  final _mudancas = StreamController<List<ResumoParcela>>.broadcast();
  StreamSubscription<void>? _assinaturaSessao;
  late final StreamSubscription<void> _assinaturaVendas;

  List<ResumoParcela>? _lista;

  List<ResumoParcela>? get lista => _lista;
  Stream<List<ResumoParcela>> get mudancas => _mudancas.stream;

  Future<Resultado<List<ResumoParcela>>> carregar() async {
    final resultado = await _vendas.listarParcelas();
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(
        _publicar([for (final dto in valor) dto.paraModel()]),
      ),
    };
  }

  /// Parcela com pagamentos, as parcelas da venda e a venda (Sucesso(null) se
  /// não existir).
  Future<Resultado<DetalheParcela?>> detalhe(String parcelaId) async {
    final parcela = await _vendas.buscarParcela(parcelaId);
    final String vendaId;
    switch (parcela) {
      case Erro(:final falha):
        return Erro(falha);
      case Sucesso(valor: null):
        return const Sucesso(null);
      case Sucesso(valor: final dto?):
        vendaId = dto.vendaId;
    }
    final (venda, parcelas, pagamentos) = await (
      _vendas.buscarResumo(vendaId),
      _vendas.listarParcelas(vendaId: vendaId),
      _recebimentos.listarPagamentos(vendaId),
    ).wait;
    switch ((venda, parcelas, pagamentos)) {
      case (Erro(:final falha), _, _) ||
          (_, Erro(:final falha), _) ||
          (_, _, Erro(:final falha)):
        return Erro(falha);
      case (Sucesso(valor: null), _, _):
        return const Sucesso(null);
      case (
        Sucesso(valor: final venda?),
        Sucesso(valor: final parcelas),
        Sucesso(valor: final pagamentos),
      ):
        final daVenda = [for (final p in parcelas) p.paraModel()];
        return Sucesso(
          DetalheParcela(
            parcela: daVenda.firstWhere((p) => p.id == parcelaId),
            pagamentos: [
              for (final p in pagamentos)
                if (p.parcelaId == parcelaId) p.paraModel(),
            ],
            parcelasDaVenda: daVenda,
            venda: venda.paraModel(),
          ),
        );
    }
  }

  /// Registra o pagamento e recarrega parcelas, vendas e clientes.
  Future<Resultado<String>> registrarPagamento({
    required String parcelaId,
    required int valorCentavos,
    required FormaPagamento forma,
    required DateTime data,
    String? observacao,
  }) async {
    final resultado = await _recebimentos.registrar(
      parcelaId: parcelaId,
      valorCentavos: valorCentavos,
      forma: forma,
      data: data,
      observacao: observacao,
    );
    if (resultado is Sucesso<String>) {
      // As vendas avisam pelo stream e a lista de parcelas recarrega junto.
      await Future.wait([_repositorioVendas.carregar(), _clientes.carregar()]);
      if (_lista == null) await carregar();
    }
    return resultado;
  }

  Future<Resultado<void>> abrirWhatsapp(String whatsapp, {String? mensagem}) =>
      _repositorioVendas.abrirWhatsapp(whatsapp, mensagem: mensagem);

  /// Compartilha a imagem do comprovante com um texto curto.
  Future<Resultado<void>> compartilharComprovante({
    required Uint8List png,
    required String texto,
  }) => _compartilhar.compartilharImagem(
    png: png,
    nomeArquivo: 'comprovante.png',
    texto: texto,
  );

  void limpar() {
    _lista = null;
    _mudancas.add(const []);
  }

  Future<void> encerrar() async {
    await _assinaturaSessao?.cancel();
    await _assinaturaVendas.cancel();
    await _mudancas.close();
  }

  List<ResumoParcela> _publicar(List<ResumoParcela> lista) {
    _lista = lista;
    _mudancas.add(lista);
    return lista;
  }
}
