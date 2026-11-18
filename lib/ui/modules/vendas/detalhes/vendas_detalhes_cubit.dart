import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/detalhe_venda.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/ui/formatadores/mensagem_cobranca.dart';
import 'package:sou_consultora/ui/modules/vendas/detalhes/vendas_detalhes_state.dart';

/// Detalhes da venda: carrega itens e parcelas, cobra no WhatsApp e cancela.
class VendasDetalhesCubit extends Cubit<VendasDetalhesState> {
  VendasDetalhesCubit({
    required this.idVenda,
    RepositorioVendas? vendas,
    RepositorioConsultora? consultora,
    DateTime Function()? agora,
  }) : _vendas = vendas ?? injetor<RepositorioVendas>(),
       _consultora = consultora ?? injetor<RepositorioConsultora>(),
       super(VendasDetalhesState(hoje: (agora ?? DateTime.now)())) {
    carregar();
  }

  final String idVenda;
  final RepositorioVendas _vendas;
  final RepositorioConsultora _consultora;

  Future<void> carregar() async {
    if (state.detalhe == null) {
      emit(state.copyWith(carregando: true, erro: () => null));
    }
    final resultado = await _vendas.detalhe(idVenda);
    if (isClosed) return;
    switch (resultado) {
      case Sucesso(valor: final DetalheVenda detalhe):
        emit(
          state.copyWith(detalhe: detalhe, carregando: false, erro: () => null),
        );
      case Sucesso(valor: null):
        emit(
          state.copyWith(
            carregando: false,
            erro: () => 'Venda não encontrada.',
          ),
        );
      case Erro(:final falha):
        if (state.detalhe != null) {
          emit(state.copyWith(aviso: () => falha.mensagem));
          return;
        }
        emit(state.copyWith(carregando: false, erro: () => falha.mensagem));
    }
  }

  void alterarAba(AbaVenda aba) => emit(state.copyWith(aba: aba));

  /// Abre o WhatsApp da cliente com a mensagem da próxima parcela em aberto.
  Future<void> cobrar() async {
    final detalhe = state.detalhe;
    final parcela = detalhe?.proximaEmAberto;
    if (detalhe == null || parcela == null) return;
    final consultora = _consultora.atual;
    final mensagem = MensagemCobranca.montar(
      parcela: parcela,
      nomeConsultora: consultora?.nome ?? '',
      chavePix: consultora?.chavePix,
    );
    final resultado = await _vendas.abrirWhatsapp(
      detalhe.venda.clienteWhatsapp,
      mensagem: mensagem,
    );
    if (isClosed) return;
    if (resultado case Erro(:final falha)) {
      emit(state.copyWith(aviso: () => falha.mensagem));
    }
  }

  Future<void> cancelar() async {
    if (state.processando) return;
    emit(state.copyWith(processando: true));
    final resultado = await _vendas.cancelar(idVenda);
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(state.copyWith(processando: false, aviso: () => falha.mensagem));
      case Sucesso():
        emit(state.copyWith(processando: false, cancelada: true));
    }
  }

  void limparAviso() => emit(state.copyWith(aviso: () => null));
}
