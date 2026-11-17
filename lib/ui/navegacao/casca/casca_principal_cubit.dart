import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/model/resumo_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/ui/navegacao/casca/casca_principal_state.dart';

class CascaPrincipalCubit extends Cubit<CascaPrincipalState> {
  CascaPrincipalCubit({
    RepositorioAutenticacao? autenticacao,
    RepositorioConsultora? consultoras,
  }) : this._(
         autenticacao ?? injetor<RepositorioAutenticacao>(),
         consultoras ?? injetor<RepositorioConsultora>(),
       );

  CascaPrincipalCubit._(this._autenticacao, RepositorioConsultora consultoras)
    : super(
        CascaPrincipalState(resumo: _resumo(_autenticacao, consultoras.atual)),
      ) {
    // O menu acompanha as edições do perfil (nome e foto).
    _assinatura = consultoras.mudancas.listen((consultora) {
      emit(state.copyWith(resumo: _resumo(_autenticacao, consultora)));
    });
  }

  final RepositorioAutenticacao _autenticacao;
  late final StreamSubscription<Consultora?> _assinatura;

  static ResumoConsultora _resumo(
    RepositorioAutenticacao autenticacao,
    Consultora? consultora,
  ) {
    if (consultora == null) return autenticacao.resumoDaConsultora();
    return ResumoConsultora.daConsultora(consultora);
  }

  Future<void> carregarVersao() async {
    final pacote = await PackageInfo.fromPlatform();
    if (isClosed) return;
    emit(state.copyWith(versao: pacote.version));
  }

  /// Encerra a sessão. A navegação para o login é feita pelo roteador.
  Future<void> sair() async {
    if (state.saindo) return;
    emit(state.copyWith(saindo: true));
    await _autenticacao.sair();
    if (isClosed) return;
    emit(state.copyWith(saindo: false));
  }

  @override
  Future<void> close() {
    _assinatura.cancel();
    return super.close();
  }
}
