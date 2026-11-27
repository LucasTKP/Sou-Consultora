import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/repository/repositorio_versao.dart';
import 'package:sou_consultora/ui/modules/atualizacao/atualizacao_state.dart';

class AtualizacaoCubit extends Cubit<AtualizacaoState> {
  AtualizacaoCubit({RepositorioVersao? repositorio})
    : _repositorio = repositorio ?? injetor<RepositorioVersao>(),
      super(const AtualizacaoInicial());

  final RepositorioVersao _repositorio;

  Future<void> abrirLoja() async {
    if (state is AtualizacaoAbrindoLoja) return;
    emit(const AtualizacaoAbrindoLoja());

    switch (await _repositorio.abrirLoja()) {
      case Sucesso():
        emit(const AtualizacaoInicial());
      case Erro(:final falha):
        emit(AtualizacaoErro(falha.mensagem));
    }
  }

  void limparErro() {
    if (state is AtualizacaoErro) emit(const AtualizacaoInicial());
  }
}
