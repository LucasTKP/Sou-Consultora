import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/ui/modules/login/acesso_login_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AcessoLoginCubit extends Cubit<AcessoLoginState> {
  AcessoLoginCubit({RepositorioAutenticacao? repositorio})
    : _repositorio = repositorio ?? injetor<RepositorioAutenticacao>(),
      super(const AcessoLoginInicial());

  final RepositorioAutenticacao _repositorio;

  Future<void> continuarComGoogle() async {
    if (state is AcessoLoginCarregandoGoogle ||
        state is AcessoLoginCarregandoApple) {
      return;
    }

    emit(const AcessoLoginCarregandoGoogle());

    final resultado = await _repositorio.continuarComGoogle();
    switch (resultado) {
      case Sucesso():
        emit(const AcessoLoginSucesso());
      case Erro(:final falha):
        emit(AcessoLoginErro(falha.mensagem));
    }
  }

  Future<void> continuarComApple() async {
    if (state is AcessoLoginCarregandoGoogle ||
        state is AcessoLoginCarregandoApple) {
      return;
    }

    emit(const AcessoLoginCarregandoApple());

    final resultado = await _repositorio.continuarComApple();
    switch (resultado) {
      case Sucesso():
        emit(const AcessoLoginSucesso());
      case Erro(:final falha):
        emit(AcessoLoginErro(falha.mensagem));
    }
  }

  void limparErro() {
    if (state is AcessoLoginErro) {
      emit(const AcessoLoginInicial());
    }
  }
}
