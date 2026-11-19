import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/detalhe_venda.dart';
import 'package:sou_consultora/core/model/forma_pagamento.dart';
import 'package:sou_consultora/core/model/item_venda.dart';
import 'package:sou_consultora/core/model/pedido_venda.dart';
import 'package:sou_consultora/core/model/plano_parcelas.dart';
import 'package:sou_consultora/core/model/resumo_cliente.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/core/repository/repositorio_servicos.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/ui/modules/vendas/nova/nova_venda_state.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

/// Pedido em 2 passos: itens e pagamento. Nova venda ou edição ([idVenda]).
class NovaVendaCubit extends Cubit<NovaVendaState> {
  NovaVendaCubit({
    String? idVenda,
    String? clienteInicialId,
    RepositorioVendas? vendas,
    RepositorioClientes? clientes,
    RepositorioProdutos? produtos,
    RepositorioServicos? servicos,
    DateTime Function()? agora,
  }) : _vendas = vendas ?? injetor<RepositorioVendas>(),
       _clientes = clientes ?? injetor<RepositorioClientes>(),
       _produtos = produtos ?? injetor<RepositorioProdutos>(),
       _servicos = servicos ?? injetor<RepositorioServicos>(),
       _agora = agora ?? DateTime.now,
       super(
         NovaVendaState(
           idVenda: idVenda,
           clienteId: clienteInicialId,
           dataVenda: _dia((agora ?? DateTime.now)()),
         ),
       ) {
    // Cliente cadastrada pelo atalho chega pelo stream.
    _assinatura = _clientes.mudancas.listen(_aoMudarClientes);
    carregar();
  }

  final RepositorioVendas _vendas;
  final RepositorioClientes _clientes;
  final RepositorioProdutos _produtos;
  final RepositorioServicos _servicos;
  final DateTime Function() _agora;
  late final StreamSubscription<List<ResumoCliente>> _assinatura;

  /// Clientes e catálogo (e, na edição, a venda).
  Future<void> carregar() async {
    emit(state.copyWith(carregando: true, erroCarregar: () => null));
    final (clientes, produtos, servicos) = await (
      _clientes.carregar(),
      _produtos.carregar(),
      _servicos.carregar(),
    ).wait;
    if (isClosed) return;
    switch ((clientes, produtos, servicos)) {
      case (Erro(:final falha), _, _) ||
          (_, Erro(:final falha), _) ||
          (_, _, Erro(:final falha)):
        _falharAoCarregar(falha.mensagem);
        return;
      case (
        Sucesso(valor: final clientes),
        Sucesso(valor: final produtos),
        Sucesso(valor: final servicos),
      ):
        emit(
          state.copyWith(
            clientes: clientes,
            produtos: produtos,
            servicos: servicos,
          ),
        );
    }
    if (!state.editando) {
      emit(state.copyWith(carregando: false));
      return;
    }
    final detalhe = await _vendas.detalhe(state.idVenda!);
    if (isClosed) return;
    switch (detalhe) {
      case Erro(:final falha):
        _falharAoCarregar(falha.mensagem);
      case Sucesso(valor: null):
        _falharAoCarregar('Venda não encontrada.');
      case Sucesso(valor: final DetalheVenda venda):
        _preencher(venda);
    }
  }

  // —— Passo 1 ——

  void alterarCliente(ResumoCliente cliente) => emit(
    state.copyWith(clienteId: () => cliente.id, erroCliente: () => null),
  );

  /// Um produto ou serviço entra uma vez só. Na edição, [indiceEditado] é ignorado.
  bool jaNoPedido(String chave, {int? indiceEditado}) {
    for (var i = 0; i < state.itens.length; i++) {
      if (i != indiceEditado && state.itens[i].chave == chave) return true;
    }
    return false;
  }

  void adicionarItem(ItemPedido item) {
    if (jaNoPedido(item.chave)) {
      emit(
        state.copyWith(
          aviso: () => const AvisoToast.aviso('Este item já está no pedido.'),
        ),
      );
      return;
    }
    emit(state.copyWith(itens: [...state.itens, item], erroItens: () => null));
  }

  void substituirItem(int indice, ItemPedido item) =>
      emit(state.copyWith(itens: [...state.itens]..[indice] = item));

  void removerItem(int indice) =>
      emit(state.copyWith(itens: [...state.itens]..removeAt(indice)));

  /// Vai ao pagamento com cliente, itens e total > 0. Refaz o plano se o
  /// total mudou desde a última vez.
  void avancar() {
    final erroCliente = state.clienteId == null ? 'Escolha a cliente' : null;
    if (state.itens.isEmpty) {
      emit(
        state.copyWith(
          erroCliente: () => erroCliente,
          erroItens: () => null,
          aviso: () => const AvisoToast.aviso(
            'Adicione pelo menos um produto ou serviço',
          ),
        ),
      );
      return;
    }
    final erroItens = state.total <= 0
        ? 'O total do pedido precisa ser maior que zero'
        : null;
    emit(
      state.copyWith(
        erroCliente: () => erroCliente,
        erroItens: () => erroItens,
      ),
    );
    if (erroCliente != null || erroItens != null) return;
    if (!PlanoParcelas.fecha(state.total, state.parcelas)) {
      _sugerirPlano(state.aVista ? 1 : _qtdDividida);
    }
    emit(state.copyWith(passo: 2));
  }

  // —— Passo 2 ——

  void voltar() => emit(state.copyWith(passo: 1));

  void alterarDataVenda(DateTime data) {
    final erro = PedidoVenda.validarDataVenda(data, hoje: _agora());
    emit(state.copyWith(dataVenda: _dia(data), erroData: () => erro));
  }

  void escolherAVista(bool aVista) {
    emit(state.copyWith(aVista: aVista));
    _sugerirPlano(aVista ? 1 : PlanoParcelas.minimoDividido);
  }

  void alterarQtdParcelas(int quantidade) => _sugerirPlano(quantidade);

  void alterarValorParcela(int indice, int centavos) => emit(
    state.copyWith(
      parcelas: [...state.parcelas]
        ..[indice] = state.parcelas[indice].copyWith(valor: centavos),
    ),
  );

  void alterarVencimento(int indice, DateTime data) => emit(
    state.copyWith(
      parcelas: [...state.parcelas]
        ..[indice] = state.parcelas[indice].copyWith(vencimento: _dia(data)),
    ),
  );

  void alterarEntrada(bool recebida) =>
      emit(state.copyWith(entradaRecebida: recebida));

  void alterarFormaEntrada(FormaPagamento forma) =>
      emit(state.copyWith(formaEntrada: forma));

  void alterarObservacoes(String texto) =>
      emit(state.copyWith(observacoes: texto));

  void limparAviso() => emit(state.copyWith(aviso: () => null));

  Future<void> concluir() async {
    if (!state.podeConcluir) return;
    emit(state.copyWith(salvando: true));
    final pedido = PedidoVenda(
      clienteId: state.clienteId!,
      dataVenda: state.dataVenda,
      itens: state.itens,
      parcelas: state.parcelas,
      observacoes: state.observacoes.trim().isEmpty ? null : state.observacoes,
      entrada: state.entradaRecebida ? state.formaEntrada : null,
    );
    final resultado = state.editando
        ? await _vendas.editar(state.idVenda!, pedido)
        : await _vendas.concluir(pedido);
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(
          state.copyWith(
            salvando: false,
            aviso: () => AvisoToast.erro(falha.mensagem),
          ),
        );
      case Sucesso(:final valor):
        emit(state.copyWith(salvando: false, idSalvo: () => valor));
    }
  }

  int get _qtdDividida => state.parcelas.length >= PlanoParcelas.minimoDividido
      ? state.parcelas.length
      : PlanoParcelas.minimoDividido;

  /// Valores iguais a partir do 1º vencimento atual (ou da data da venda).
  void _sugerirPlano(int quantidade) {
    final primeiro = state.parcelas.isEmpty
        ? state.dataVenda
        : state.parcelas.first.vencimento;
    emit(
      state.copyWith(
        parcelas: PlanoParcelas.sugerir(
          total: state.total,
          quantidade: quantidade,
          primeiroVencimento: primeiro,
        ),
        versaoPlano: state.versaoPlano + 1,
      ),
    );
  }

  void _preencher(DetalheVenda detalhe) {
    final venda = detalhe.venda;
    emit(
      state.copyWith(
        carregando: false,
        clienteId: () => venda.clienteId,
        itens: [for (final item in detalhe.itens) _itemDoPedido(item)],
        dataVenda: _dia(venda.dataVenda),
        aVista: detalhe.parcelas.length <= 1,
        parcelas: [
          for (final p in detalhe.parcelas)
            ParcelaPlano(valor: p.valor, vencimento: p.vencimento),
        ],
        versaoPlano: state.versaoPlano + 1,
        observacoes: venda.observacoes ?? '',
        versaoPreenchimento: state.versaoPreenchimento + 1,
      ),
    );
  }

  /// O preço vem do catálogo atual (a função regrava com ele). Na edição, o
  /// saldo inclui o que esta venda baixou (volta ao estoque antes de regravar).
  ItemPedido _itemDoPedido(ItemVendido item) {
    if (item.tipo == TipoItem.servico) {
      final servico = state.servicos
          .where((s) => s.id == item.catalogoId)
          .firstOrNull;
      return ItemPedido(
        tipo: TipoItem.servico,
        catalogoId: item.catalogoId,
        nome: item.nome,
        precoUnitario: servico?.precoCobrado ?? item.precoUnitario,
        quantidade: item.quantidade,
        desconto: item.desconto,
        baixarEstoque: false,
        urlFoto: servico?.urlFoto,
        categoriaServico: item.categoriaServico,
      );
    }
    final produto = state.produtos
        .where((p) => p.id == item.catalogoId)
        .firstOrNull;
    return ItemPedido(
      tipo: TipoItem.produto,
      catalogoId: item.catalogoId,
      nome: item.nome,
      precoUnitario: produto?.precoVenda ?? item.precoUnitario,
      quantidade: item.quantidade,
      desconto: item.desconto,
      baixarEstoque: item.baixarEstoque,
      saldoEstoque:
          (produto?.qtdDisponivel ?? 0) +
          (item.baixarEstoque ? item.quantidade : 0),
      urlFoto: produto?.urlFoto,
    );
  }

  void _aoMudarClientes(List<ResumoCliente> lista) {
    if (isClosed || lista.isEmpty) return;
    emit(state.copyWith(clientes: lista));
  }

  void _falharAoCarregar(String mensagem) =>
      emit(state.copyWith(carregando: false, erroCarregar: () => mensagem));

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Future<void> close() async {
    await _assinatura.cancel();
    return super.close();
  }
}
