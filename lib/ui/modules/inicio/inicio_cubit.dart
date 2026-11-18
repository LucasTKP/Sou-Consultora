import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/model/resumo_inicio.dart';
import 'package:sou_consultora/core/repository/repositorio_boletos.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_inicio.dart';
import 'package:sou_consultora/core/repository/repositorio_recebimentos.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/ui/formatadores/mensagem_recompra.dart';
import 'package:sou_consultora/ui/modules/inicio/inicio_state.dart';

/// Início: carrega vendas, parcelas, boletos, pagamentos e lembretes em
/// paralelo e recalcula quando vendas, parcelas ou boletos mudam.
class InicioCubit extends Cubit<InicioState> {
  InicioCubit({
    RepositorioVendas? vendas,
    RepositorioRecebimentos? recebimentos,
    RepositorioBoletos? boletos,
    RepositorioInicio? inicio,
    RepositorioConsultora? consultora,
    DateTime Function()? agora,
  }) : _vendas = vendas ?? injetor<RepositorioVendas>(),
       _recebimentos = recebimentos ?? injetor<RepositorioRecebimentos>(),
       _boletos = boletos ?? injetor<RepositorioBoletos>(),
       _inicio = inicio ?? injetor<RepositorioInicio>(),
       _consultora = consultora ?? injetor<RepositorioConsultora>(),
       super(InicioState(hoje: (agora ?? DateTime.now)())) {
    emit(state.copyWith(consultora: () => _consultora.atual));
    _assinaturas = [
      _consultora.mudancas.listen(_aoMudarConsultora),
      // Venda nova muda vendas e lembretes; pagamento muda parcelas e
      // pagamentos; boleto muda os alertas.
      _vendas.mudancas.listen((_) => _aoMudar()),
      _recebimentos.mudancas.listen((_) => _aoMudar()),
      _boletos.mudancas.listen((_) => _aoMudar()),
    ];
    carregar();
  }

  final RepositorioVendas _vendas;
  final RepositorioRecebimentos _recebimentos;
  final RepositorioBoletos _boletos;
  final RepositorioInicio _inicio;
  final RepositorioConsultora _consultora;
  late final List<StreamSubscription<Object?>> _assinaturas;

  Future<void> carregar() async {
    if (state.carregamento != CarregamentoInicio.pronto) {
      emit(state.copyWith(carregamento: CarregamentoInicio.carregando));
    }
    final (vendas, parcelas, boletos, pagamentos, lembretes) = await (
      _vendas.carregar(),
      _recebimentos.carregar(),
      _boletos.carregar(),
      _inicio.pagamentos(),
      _inicio.lembretes(),
    ).wait;
    if (isClosed) return;
    switch ((vendas, parcelas, boletos, pagamentos, lembretes)) {
      case (Erro(:final falha), _, _, _, _) ||
          (_, Erro(:final falha), _, _, _) ||
          (_, _, Erro(:final falha), _, _) ||
          (_, _, _, Erro(:final falha), _) ||
          (_, _, _, _, Erro(:final falha)):
        _aoFalhar(falha.mensagem);
      case (
        Sucesso(valor: final vendas),
        Sucesso(valor: final parcelas),
        Sucesso(valor: final boletos),
        Sucesso(valor: final pagamentos),
        Sucesso(valor: final lembretes),
      ):
        emit(
          state.copyWith(
            carregamento: CarregamentoInicio.pronto,
            vendas: vendas,
            parcelas: parcelas,
            boletos: boletos,
            pagamentos: pagamentos,
            lembretes: lembretes,
            mensagemErro: () => null,
          ),
        );
    }
  }

  /// Abre o WhatsApp da cliente com a mensagem de recompra.
  Future<void> lembrarRecompra(LembreteAtivo ativo) async {
    final resultado = await _inicio.abrirWhatsapp(
      ativo.lembrete.clienteWhatsapp,
      MensagemRecompra.montar(
        lembrete: ativo.lembrete,
        diasDesdeCompra: ativo.diasDesdeCompra,
        nomeConsultora: state.consultora?.nome ?? '',
      ),
    );
    if (isClosed) return;
    if (resultado case Erro(:final falha)) {
      emit(state.copyWith(aviso: () => falha.mensagem));
    }
  }

  void limparAviso() => emit(state.copyWith(aviso: () => null));

  /// Nome e foto do cumprimento acompanham o perfil.
  void _aoMudarConsultora(Consultora? consultora) {
    if (!isClosed) emit(state.copyWith(consultora: () => consultora));
  }

  /// Uma lista mudou em outro módulo: usa as listas em cache e relê o que
  /// só o Início tem (pagamentos e lembretes).
  Future<void> _aoMudar() async {
    if (isClosed || state.carregamento != CarregamentoInicio.pronto) return;
    emit(
      state.copyWith(
        vendas: _vendas.lista ?? state.vendas,
        parcelas: _recebimentos.lista ?? state.parcelas,
        boletos: _boletos.lista ?? state.boletos,
      ),
    );
    final (pagamentos, lembretes) = await (
      _inicio.pagamentos(),
      _inicio.lembretes(),
    ).wait;
    if (isClosed) return;
    emit(
      state.copyWith(
        pagamentos: switch (pagamentos) {
          Sucesso(:final valor) => valor,
          Erro() => null,
        },
        lembretes: switch (lembretes) {
          Sucesso(:final valor) => valor,
          Erro() => null,
        },
      ),
    );
  }

  void _aoFalhar(String mensagem) {
    if (state.carregamento == CarregamentoInicio.pronto) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoInicio.erro,
        mensagemErro: () => mensagem,
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final assinatura in _assinaturas) {
      await assinatura.cancel();
    }
    return super.close();
  }
}
