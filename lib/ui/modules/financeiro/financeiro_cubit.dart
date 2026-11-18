import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/repository/repositorio_boletos.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/ui/modules/financeiro/financeiro_state.dart';

/// Financeiro: carrega vendas e boletos, acompanha os dois repositórios
/// (recalcula quando uma venda ou um boleto muda) e guarda o período.
class FinanceiroCubit extends Cubit<FinanceiroState> {
  FinanceiroCubit({
    RepositorioVendas? vendas,
    RepositorioBoletos? boletos,
    DateTime Function()? agora,
  }) : _vendas = vendas ?? injetor<RepositorioVendas>(),
       _boletos = boletos ?? injetor<RepositorioBoletos>(),
       super(_inicial((agora ?? DateTime.now)())) {
    final vendasEmCache = _vendas.lista;
    final boletosEmCache = _boletos.lista;
    if (vendasEmCache != null && boletosEmCache != null) {
      emit(
        state.copyWith(
          vendas: vendasEmCache,
          boletos: boletosEmCache,
          carregamento: CarregamentoFinanceiro.pronto,
        ),
      );
    }
    _assinaturas = [
      _vendas.mudancas.listen((_) => _aoMudar()),
      _boletos.mudancas.listen((_) => _aoMudar()),
    ];
    carregar();
  }

  final RepositorioVendas _vendas;
  final RepositorioBoletos _boletos;
  late final List<StreamSubscription<Object?>> _assinaturas;

  static FinanceiroState _inicial(DateTime hoje) =>
      FinanceiroState(hoje: hoje, periodo: MesAno.de(hoje));

  Future<void> carregar() async {
    if (state.carregamento != CarregamentoFinanceiro.pronto) {
      emit(state.copyWith(carregamento: CarregamentoFinanceiro.carregando));
    }
    final (vendas, boletos) = await (
      _vendas.carregar(),
      _boletos.carregar(),
    ).wait;
    if (isClosed) return;
    switch ((vendas, boletos)) {
      case (Erro(:final falha), _) || (_, Erro(:final falha)):
        _aoFalhar(falha.mensagem);
      case (Sucesso(valor: final vendas), Sucesso(valor: final boletos)):
        emit(
          state.copyWith(
            vendas: vendas,
            boletos: boletos,
            carregamento: CarregamentoFinanceiro.pronto,
            mensagemErro: () => null,
          ),
        );
    }
  }

  void alterarPeriodo(MesAno periodo) => emit(state.copyWith(periodo: periodo));

  /// Um repositório avisou mudança (venda feita, boleto pago...). Só vale
  /// depois da primeira carga completa.
  void _aoMudar() {
    if (isClosed || state.carregamento != CarregamentoFinanceiro.pronto) {
      return;
    }
    emit(
      state.copyWith(
        vendas: _vendas.lista ?? state.vendas,
        boletos: _boletos.lista ?? state.boletos,
      ),
    );
  }

  void _aoFalhar(String mensagem) {
    if (state.carregamento == CarregamentoFinanceiro.pronto) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoFinanceiro.erro,
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
