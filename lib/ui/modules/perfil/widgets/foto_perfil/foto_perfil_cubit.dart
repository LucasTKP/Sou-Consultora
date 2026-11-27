import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/model/origem_foto.dart';
import 'package:sou_consultora/core/model/resumo_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/ui/modules/perfil/widgets/foto_perfil/foto_perfil_state.dart';

/// Foto da consultora: acompanha o repositório e troca/remove a foto.
class FotoPerfilCubit extends Cubit<FotoPerfilState> {
  FotoPerfilCubit({RepositorioConsultora? repositorio})
    : this._(repositorio ?? injetor<RepositorioConsultora>());

  FotoPerfilCubit._(this._repositorio) : super(_estadoDe(_repositorio.atual)) {
    _assinatura = _repositorio.mudancas.listen(
      (consultora) => emit(_estadoDe(consultora)),
    );
  }

  final RepositorioConsultora _repositorio;
  late final StreamSubscription<Consultora?> _assinatura;

  static FotoPerfilState _estadoDe(
    Consultora? consultora, {
    bool processando = false,
    String? erro,
  }) {
    if (consultora == null) {
      return FotoPerfilState(processando: processando, erro: erro);
    }
    final resumo = ResumoConsultora.daConsultora(consultora);
    return FotoPerfilState(
      urlFoto: resumo.fotoUrl,
      iniciais: resumo.iniciais,
      processando: processando,
      erro: erro,
    );
  }

  Future<void> trocar(OrigemFoto origem) async {
    final escolha = await _repositorio.escolherFoto(origem);
    switch (escolha) {
      case Erro(:final falha):
        _mostrarErro(falha.mensagem);
      case Sucesso(valor: null):
        return;
      case Sucesso(:final valor?):
        _emitirProcessando();
        _aoTerminar(await _repositorio.trocarFoto(valor));
    }
  }

  Future<void> remover() async {
    _emitirProcessando();
    _aoTerminar(await _repositorio.removerFoto());
  }

  void limparErro() => emit(_estadoDe(_repositorio.atual));

  void _emitirProcessando() =>
      emit(_estadoDe(_repositorio.atual, processando: true));

  void _aoTerminar(Resultado<Consultora> resultado) {
    if (isClosed) return;
    if (resultado case Erro(:final falha)) {
      _mostrarErro(falha.mensagem);
      return;
    }
    emit(_estadoDe(_repositorio.atual));
  }

  void _mostrarErro(String mensagem) =>
      emit(_estadoDe(_repositorio.atual, erro: mensagem));

  @override
  Future<void> close() {
    _assinatura.cancel();
    return super.close();
  }
}
