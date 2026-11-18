import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/detalhe_parcela.dart';
import 'package:sou_consultora/core/model/forma_pagamento.dart';
import 'package:sou_consultora/core/model/pagamento.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_recebimentos.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/ui/formatadores/mensagem_cobranca.dart';
import 'package:sou_consultora/ui/modules/a_receber/parcela/a_receber_parcela_state.dart';

/// Detalhes da parcela: carrega, cobra no WhatsApp, registra pagamento
/// (validando valor e data) e cancela a venda.
class AReceberParcelaCubit extends Cubit<AReceberParcelaState> {
  AReceberParcelaCubit({
    required this.idParcela,
    RepositorioRecebimentos? recebimentos,
    RepositorioVendas? vendas,
    RepositorioConsultora? consultora,
    DateTime Function()? agora,
  }) : _recebimentos = recebimentos ?? injetor<RepositorioRecebimentos>(),
       _vendas = vendas ?? injetor<RepositorioVendas>(),
       _consultora = consultora ?? injetor<RepositorioConsultora>(),
       _agora = agora ?? DateTime.now,
       super(AReceberParcelaState(hoje: (agora ?? DateTime.now)())) {
    carregar();
  }

  final String idParcela;
  final RepositorioRecebimentos _recebimentos;
  final RepositorioVendas _vendas;
  final RepositorioConsultora _consultora;
  final DateTime Function() _agora;

  Future<void> carregar() async {
    if (state.detalhe == null) {
      emit(state.copyWith(carregando: true, erro: () => null));
    }
    final resultado = await _recebimentos.detalhe(idParcela);
    if (isClosed) return;
    switch (resultado) {
      case Sucesso(valor: final DetalheParcela detalhe):
        emit(
          state.copyWith(detalhe: detalhe, carregando: false, erro: () => null),
        );
      case Sucesso(valor: null):
        emit(
          state.copyWith(
            carregando: false,
            erro: () => 'Parcela não encontrada.',
          ),
        );
      case Erro(:final falha):
        _aoFalharCarregar(falha.mensagem);
    }
  }

  /// Abre o WhatsApp da cliente com a mensagem desta parcela.
  Future<void> cobrar() async {
    final parcela = state.detalhe?.parcela;
    if (parcela == null || parcela.paga) return;
    final consultora = _consultora.atual;
    final resultado = await _recebimentos.abrirWhatsapp(
      parcela.clienteWhatsapp,
      mensagem: MensagemCobranca.montar(
        parcela: parcela,
        nomeConsultora: consultora?.nome ?? '',
        chavePix: consultora?.chavePix,
      ),
    );
    if (isClosed) return;
    if (resultado case Erro(:final falha)) {
      emit(state.copyWith(aviso: () => falha.mensagem));
    }
  }

  /// Limpa os erros da folha ao abri-la de novo.
  void prepararPagamento() => emit(
    state.copyWith(
      erroValor: () => null,
      erroData: () => null,
      erroPagamento: () => null,
    ),
  );

  /// Valida e grava o pagamento. Devolve o id gravado (a folha fecha e o
  /// comprovante abre) ou null quando não gravou.
  Future<String?> registrarPagamento({
    required int valorCentavos,
    required FormaPagamento forma,
    required DateTime data,
    String? observacao,
  }) async {
    final parcela = state.detalhe?.parcela;
    if (parcela == null || state.registrando) return null;
    final erroValor = Pagamento.validarValor(
      valorCentavos,
      saldo: parcela.saldo,
    );
    final erroData = Pagamento.validarData(data, hoje: _agora());
    emit(
      state.copyWith(
        erroValor: () => erroValor,
        erroData: () => erroData,
        erroPagamento: () => null,
      ),
    );
    if (erroValor != null || erroData != null) return null;

    emit(state.copyWith(registrando: true));
    final texto = observacao?.trim() ?? '';
    final resultado = await _recebimentos.registrarPagamento(
      parcelaId: parcela.id,
      valorCentavos: valorCentavos,
      forma: forma,
      data: data,
      observacao: texto.isEmpty ? null : texto,
    );
    if (isClosed) return null;
    switch (resultado) {
      case Erro(:final falha):
        emit(
          state.copyWith(
            registrando: false,
            erroPagamento: () => falha.mensagem,
          ),
        );
        return null;
      case Sucesso(valor: final id):
        emit(state.copyWith(registrando: false));
        await carregar();
        return id;
    }
  }

  Future<void> cancelarVenda() async {
    final detalhe = state.detalhe;
    if (detalhe == null || state.cancelando) return;
    emit(state.copyWith(cancelando: true));
    final resultado = await _vendas.cancelar(detalhe.venda.id);
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(state.copyWith(cancelando: false, aviso: () => falha.mensagem));
      case Sucesso():
        emit(state.copyWith(cancelando: false, cancelada: true));
    }
  }

  void limparAviso() => emit(state.copyWith(aviso: () => null));

  void _aoFalharCarregar(String mensagem) {
    if (state.detalhe != null) {
      emit(state.copyWith(aviso: () => mensagem));
      return;
    }
    emit(state.copyWith(carregando: false, erro: () => mensagem));
  }
}
