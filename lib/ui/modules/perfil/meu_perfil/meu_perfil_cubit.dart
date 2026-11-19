import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_suporte.dart';
import 'package:sou_consultora/ui/formatadores/mensagem_suporte.dart';
import 'package:sou_consultora/ui/modules/perfil/meu_perfil/meu_perfil_state.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

class MeuPerfilCubit extends Cubit<MeuPerfilState> {
  MeuPerfilCubit({
    RepositorioConsultora? consultoras,
    RepositorioAutenticacao? autenticacao,
    RepositorioSuporte? suporte,
  }) : this._(
         consultoras ?? injetor<RepositorioConsultora>(),
         autenticacao ?? injetor<RepositorioAutenticacao>(),
         suporte,
       );

  MeuPerfilCubit._(
    RepositorioConsultora consultoras,
    this._autenticacao,
    this._suporte,
  ) : super(MeuPerfilState(consultora: consultoras.atual)) {
    _assinatura = consultoras.mudancas.listen(
      (consultora) =>
          emit(MeuPerfilState(consultora: consultora, saindo: state.saindo)),
    );
  }

  final RepositorioAutenticacao _autenticacao;

  /// Resolvido só quando preciso (a maioria das telas nunca fala com o suporte).
  final RepositorioSuporte? _suporte;
  late final StreamSubscription<Consultora?> _assinatura;

  /// O roteador leva ao login quando a sessão termina.
  Future<void> sair() async {
    if (state.saindo) return;
    emit(MeuPerfilState(consultora: state.consultora, saindo: true));
    await _autenticacao.sair();
  }

  /// Abre o WhatsApp do suporte com o pedido de apagar a conta já escrito: a
  /// exclusão é feita pelo suporte.
  Future<void> pedirParaApagarConta() async {
    final suporte = _suporte ?? injetor<RepositorioSuporte>();
    final resultado = await suporte.abrirConversa(MensagemSuporte.apagarConta);
    if (isClosed) return;
    if (resultado case Erro(:final falha)) {
      emit(
        MeuPerfilState(
          consultora: state.consultora,
          saindo: state.saindo,
          aviso: AvisoToast.erro(falha.mensagem),
        ),
      );
    }
  }

  void limparAviso() =>
      emit(MeuPerfilState(consultora: state.consultora, saindo: state.saindo));

  @override
  Future<void> close() {
    _assinatura.cancel();
    return super.close();
  }
}
