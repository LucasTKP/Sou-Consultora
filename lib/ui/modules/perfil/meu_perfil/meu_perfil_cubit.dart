import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/ui/modules/perfil/meu_perfil/meu_perfil_state.dart';

class MeuPerfilCubit extends Cubit<MeuPerfilState> {
  MeuPerfilCubit({
    RepositorioConsultora? consultoras,
    RepositorioAutenticacao? autenticacao,
  }) : this._(
         consultoras ?? injetor<RepositorioConsultora>(),
         autenticacao ?? injetor<RepositorioAutenticacao>(),
       );

  MeuPerfilCubit._(RepositorioConsultora consultoras, this._autenticacao)
    : super(MeuPerfilState(consultora: consultoras.atual)) {
    _assinatura = consultoras.mudancas.listen(
      (consultora) =>
          emit(MeuPerfilState(consultora: consultora, saindo: state.saindo)),
    );
  }

  final RepositorioAutenticacao _autenticacao;
  late final StreamSubscription<Consultora?> _assinatura;

  /// O roteador leva ao login quando a sessão termina.
  Future<void> sair() async {
    if (state.saindo) return;
    emit(MeuPerfilState(consultora: state.consultora, saindo: true));
    await _autenticacao.sair();
  }

  @override
  Future<void> close() {
    _assinatura.cancel();
    return super.close();
  }
}
