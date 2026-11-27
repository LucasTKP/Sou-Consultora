import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/core/model/resumo_inicio.dart';
import 'package:sou_consultora/core/model/resumo_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_recebimentos.dart';
import 'package:sou_consultora/ui/navegacao/casca/casca_principal_state.dart';

class CascaPrincipalCubit extends Cubit<CascaPrincipalState> {
  CascaPrincipalCubit({
    RepositorioAutenticacao? autenticacao,
    RepositorioConsultora? consultoras,
    RepositorioRecebimentos? recebimentos,
    DateTime Function()? agora,
  }) : this._(
         autenticacao ?? injetor<RepositorioAutenticacao>(),
         consultoras ?? injetor<RepositorioConsultora>(),
         recebimentos ?? injetor<RepositorioRecebimentos>(),
         agora ?? DateTime.now,
       );

  CascaPrincipalCubit._(
    this._autenticacao,
    RepositorioConsultora consultoras,
    RepositorioRecebimentos recebimentos,
    this._agora,
  ) : super(
        CascaPrincipalState(
          resumo: _resumo(_autenticacao, consultoras.atual),
          qtdAtrasadas: _atrasadas(recebimentos.lista, _agora()),
        ),
      ) {
    // O menu acompanha as edições do perfil (nome e foto).
    _assinatura = consultoras.mudancas.listen((consultora) {
      emit(state.copyWith(resumo: _resumo(_autenticacao, consultora)));
    });
    // E o selo de A Receber acompanha as parcelas (pagamento, venda nova...).
    _assinaturaParcelas = recebimentos.mudancas.listen(_aoMudarParcelas);
  }

  final RepositorioAutenticacao _autenticacao;
  final DateTime Function() _agora;
  late final StreamSubscription<Consultora?> _assinatura;
  late final StreamSubscription<List<ResumoParcela>> _assinaturaParcelas;

  void _aoMudarParcelas(List<ResumoParcela> parcelas) {
    if (isClosed) return;
    emit(state.copyWith(qtdAtrasadas: _atrasadas(parcelas, _agora())));
  }

  static int _atrasadas(List<ResumoParcela>? parcelas, DateTime hoje) =>
      ResumoInicio.atrasadasDe(parcelas ?? const [], hoje: hoje)?.qtdParcelas ??
      0;

  static ResumoConsultora _resumo(
    RepositorioAutenticacao autenticacao,
    Consultora? consultora,
  ) {
    if (consultora == null) return autenticacao.resumoDaConsultora();
    return ResumoConsultora.daConsultora(consultora);
  }

  @override
  Future<void> close() {
    _assinatura.cancel();
    _assinaturaParcelas.cancel();
    return super.close();
  }
}
