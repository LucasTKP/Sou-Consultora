import 'dart:async';

import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/detalhe_venda.dart';
import 'package:sou_consultora/core/model/item_venda.dart';
import 'package:sou_consultora/core/model/pedido_venda.dart';
import 'package:sou_consultora/core/model/venda.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/core/service/servico_vendas.dart';
import 'package:sou_consultora/core/service/servico_whatsapp.dart';

/// Vendas da consultora logada.
///
/// Guarda a última lista e avisa em [mudancas]. Depois de concluir, editar ou
/// cancelar, recarrega as vendas, os produtos (estoque) e as clientes (saldo).
class RepositorioVendas {
  RepositorioVendas({
    required this._servico,
    required this._produtos,
    required this._clientes,
    required this._whatsapp,
    Stream<void>? sessaoEncerrada,
  }) {
    _assinaturaSessao = sessaoEncerrada?.listen((_) => limpar());
  }

  final ServicoVendas _servico;
  final RepositorioProdutos _produtos;
  final RepositorioClientes _clientes;
  final ServicoWhatsapp _whatsapp;
  final _mudancas = StreamController<List<ResumoVenda>>.broadcast();
  StreamSubscription<void>? _assinaturaSessao;

  List<ResumoVenda>? _lista;

  List<ResumoVenda>? get lista => _lista;
  Stream<List<ResumoVenda>> get mudancas => _mudancas.stream;

  Future<Resultado<List<ResumoVenda>>> carregar() async {
    final resultado = await _servico.listarResumos();
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(
        _publicar([for (final dto in valor) dto.paraModel()]),
      ),
    };
  }

  ResumoVenda? resumoEmCache(String id) {
    for (final venda in _lista ?? const <ResumoVenda>[]) {
      if (venda.id == id) return venda;
    }
    return null;
  }

  /// Venda com itens (fotos assinadas) e parcelas (Sucesso(null) se não existir).
  Future<Resultado<DetalheVenda?>> detalhe(String id) async {
    final (resumo, itens, parcelas) = await (
      _servico.buscarResumo(id),
      _servico.listarItens(id),
      _servico.listarParcelas(vendaId: id),
    ).wait;
    switch ((resumo, itens, parcelas)) {
      case (Erro(:final falha), _, _) ||
          (_, Erro(:final falha), _) ||
          (_, _, Erro(:final falha)):
        return Erro(falha);
      case (Sucesso(valor: null), _, _):
        return const Sucesso(null);
      case (
        Sucesso(valor: final venda?),
        Sucesso(valor: final itens),
        Sucesso(valor: final parcelas),
      ):
        return Sucesso(
          DetalheVenda(
            venda: venda.paraModel(),
            itens: await _comFotos([for (final i in itens) i.paraModel()]),
            parcelas: [for (final p in parcelas) p.paraModel()],
          ),
        );
    }
  }

  /// Vendas e parcelas de uma cliente.
  Future<Resultado<ComprasCliente>> compras(String clienteId) async {
    final (vendas, parcelas) = await (
      _servico.listarResumos(clienteId: clienteId),
      _servico.listarParcelas(clienteId: clienteId),
    ).wait;
    return switch ((vendas, parcelas)) {
      (Erro(:final falha), _) || (_, Erro(:final falha)) => Erro(falha),
      (Sucesso(valor: final vendas), Sucesso(valor: final parcelas)) => Sucesso(
        ComprasCliente(
          vendas: [for (final v in vendas) v.paraModel()],
          parcelas: [for (final p in parcelas) p.paraModel()],
        ),
      ),
    };
  }

  Future<Resultado<String>> concluir(PedidoVenda pedido) =>
      _depoisDeGravar(_servico.concluir(pedido));

  Future<Resultado<String>> editar(String id, PedidoVenda pedido) =>
      _depoisDeGravar(_servico.editar(id, pedido));

  Future<Resultado<void>> cancelar(String id) =>
      _depoisDeGravar(_servico.cancelar(id));

  /// Abre a conversa com a cliente, com a mensagem de cobrança.
  Future<Resultado<void>> abrirWhatsapp(String whatsapp, {String? mensagem}) =>
      _whatsapp.abrirConversa(whatsapp, mensagem: mensagem);

  void limpar() {
    _lista = null;
    _mudancas.add(const []);
  }

  Future<void> encerrar() async {
    await _assinaturaSessao?.cancel();
    await _mudancas.close();
  }

  /// A gravação já valeu; se recarregar falhar, as listas atualizam depois.
  Future<Resultado<T>> _depoisDeGravar<T>(Future<Resultado<T>> gravar) async {
    final resultado = await gravar;
    if (resultado is Sucesso<T>) {
      await Future.wait([
        carregar(),
        _produtos.carregar(),
        _clientes.carregar(),
      ]);
    }
    return resultado;
  }

  Future<List<ItemVendido>> _comFotos(List<ItemVendido> itens) async {
    final caminhos = [for (final i in itens) ?i.caminhoFoto];
    if (caminhos.isEmpty) return itens;
    final urls = switch (await _servico.urlsDasFotos(caminhos)) {
      Sucesso(:final valor) => valor,
      Erro() => const <String, String>{},
    };
    return [for (final i in itens) i.comUrl(urls[i.caminhoFoto])];
  }

  List<ResumoVenda> _publicar(List<ResumoVenda> lista) {
    _lista = lista;
    _mudancas.add(lista);
    return lista;
  }
}
