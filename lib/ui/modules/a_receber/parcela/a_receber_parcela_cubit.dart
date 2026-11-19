import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/detalhe_parcela.dart';
import 'package:sou_consultora/core/model/forma_pagamento.dart';
import 'package:sou_consultora/core/model/pagamento.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_recebimentos.dart';
import 'package:sou_consultora/ui/formatadores/mensagem_cobranca.dart';
import 'package:sou_consultora/ui/modules/a_receber/parcela/a_receber_parcela_state.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

/// Detalhes da parcela: carrega, cobra no WhatsApp, registra, corrige e exclui
/// pagamentos, e edita o cronograma da venda (validando valor e data).
class AReceberParcelaCubit extends Cubit<AReceberParcelaState> {
  AReceberParcelaCubit({
    required this.idParcela,
    RepositorioRecebimentos? recebimentos,
    RepositorioConsultora? consultora,
    DateTime Function()? agora,
  }) : _recebimentos = recebimentos ?? injetor<RepositorioRecebimentos>(),
       _consultora = consultora ?? injetor<RepositorioConsultora>(),
       _agora = agora ?? DateTime.now,
       super(AReceberParcelaState(hoje: (agora ?? DateTime.now)())) {
    carregar();
  }

  final String idParcela;
  final RepositorioRecebimentos _recebimentos;
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
      emit(state.copyWith(aviso: () => AvisoToast.erro(falha.mensagem)));
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

  /// Corrige um pagamento. O saldo para ele é o saldo da parcela mais o que
  /// ele já ocupa. Devolve true quando gravou.
  Future<bool> editarPagamento({
    required String pagamentoId,
    required int valorCentavos,
    required FormaPagamento forma,
    required DateTime data,
    String? observacao,
  }) async {
    final detalhe = state.detalhe;
    if (detalhe == null || state.registrando) return false;
    final pagamento = detalhe.pagamentos
        .where((p) => p.id == pagamentoId)
        .firstOrNull;
    if (pagamento == null) return false;
    final saldo = detalhe.parcela.saldo + pagamento.valor;
    final erroValor = Pagamento.validarValor(valorCentavos, saldo: saldo);
    final erroData = Pagamento.validarData(data, hoje: _agora());
    emit(
      state.copyWith(
        erroValor: () => erroValor,
        erroData: () => erroData,
        erroPagamento: () => null,
      ),
    );
    if (erroValor != null || erroData != null) return false;

    emit(state.copyWith(registrando: true));
    final texto = observacao?.trim() ?? '';
    final resultado = await _recebimentos.editarPagamento(
      pagamentoId: pagamentoId,
      valorCentavos: valorCentavos,
      forma: forma,
      data: data,
      observacao: texto.isEmpty ? null : texto,
    );
    if (isClosed) return false;
    switch (resultado) {
      case Erro(:final falha):
        emit(
          state.copyWith(
            registrando: false,
            erroPagamento: () => falha.mensagem,
          ),
        );
        return false;
      case Sucesso():
        emit(state.copyWith(registrando: false));
        await carregar();
        return true;
    }
  }

  /// Exclui um pagamento lançado por engano. Devolve true quando excluiu.
  Future<bool> excluirPagamento(String pagamentoId) async {
    if (state.registrando) return false;
    emit(state.copyWith(registrando: true));
    final resultado = await _recebimentos.excluirPagamento(pagamentoId);
    if (isClosed) return false;
    switch (resultado) {
      case Erro(:final falha):
        emit(
          state.copyWith(
            registrando: false,
            erroPagamento: () => falha.mensagem,
          ),
        );
        return false;
      case Sucesso():
        emit(state.copyWith(registrando: false));
        await carregar();
        return true;
    }
  }

  /// Limpa o erro da folha Editar parcelas ao abri-la.
  void prepararParcelas() => emit(state.copyWith(erroParcelas: () => null));

  /// Regrava valor e vencimento de todas as parcelas da venda. Devolve true
  /// quando gravou; o erro (ex.: a soma não bate) vai para [erroParcelas].
  Future<bool> editarParcelas(
    List<({String id, int valorCentavos, DateTime vencimento})> parcelas,
  ) async {
    final detalhe = state.detalhe;
    if (detalhe == null || state.registrando) return false;
    emit(state.copyWith(registrando: true, erroParcelas: () => null));
    final resultado = await _recebimentos.editarParcelas(
      vendaId: detalhe.venda.id,
      parcelas: parcelas,
    );
    if (isClosed) return false;
    switch (resultado) {
      case Erro(:final falha):
        emit(
          state.copyWith(
            registrando: false,
            erroParcelas: () => falha.mensagem,
          ),
        );
        return false;
      case Sucesso():
        emit(state.copyWith(registrando: false));
        await carregar();
        return true;
    }
  }

  void limparAviso() => emit(state.copyWith(aviso: () => null));

  void _aoFalharCarregar(String mensagem) {
    if (state.detalhe != null) {
      emit(state.copyWith(aviso: () => AvisoToast.erro(mensagem)));
      return;
    }
    emit(state.copyWith(carregando: false, erro: () => mensagem));
  }
}
