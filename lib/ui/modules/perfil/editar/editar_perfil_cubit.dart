import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/chave_pix.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/ui/formatadores/formatador_chave_pix.dart';
import 'package:sou_consultora/ui/formatadores/formatador_telefone.dart';
import 'package:sou_consultora/ui/modules/perfil/editar/editar_perfil_state.dart';

class EditarPerfilCubit extends Cubit<EditarPerfilState> {
  EditarPerfilCubit({RepositorioConsultora? repositorio})
    : this._(repositorio ?? injetor<RepositorioConsultora>());

  EditarPerfilCubit._(this._repositorio)
    : super(_estadoInicial(_repositorio.atual));

  final RepositorioConsultora _repositorio;

  static EditarPerfilState _estadoInicial(Consultora? consultora) {
    final chave = consultora?.chavePix;
    return EditarPerfilState(
      nome: consultora?.nome ?? '',
      whatsapp: FormatadorTelefone.formatar(consultora?.whatsapp ?? ''),
      tipoPix: chave?.tipo,
      chavePix: chave == null ? '' : FormatadorChavePix.formatar(chave),
    );
  }

  void alterarNome(String valor) =>
      emit(state.copyWith(nome: valor, erroNome: () => null));

  void alterarWhatsapp(String valor) =>
      emit(state.copyWith(whatsapp: valor, erroWhatsapp: () => null));

  /// Trocar o tipo apaga a chave digitada (o formato muda).
  void alterarTipoPix(TipoChavePix tipo) {
    if (tipo == state.tipoPix) return;
    emit(
      state.copyWith(
        tipoPix: () => tipo,
        chavePix: '',
        erroTipoPix: () => null,
        erroChavePix: () => null,
      ),
    );
  }

  void alterarChavePix(String valor) => emit(
    state.copyWith(
      chavePix: valor,
      erroChavePix: () => null,
      erroTipoPix: () => null,
    ),
  );

  void removerChavePix() {
    emit(
      state.copyWith(
        tipoPix: () => null,
        chavePix: '',
        erroTipoPix: () => null,
        erroChavePix: () => null,
      ),
    );
  }

  void limparErroGeral() => emit(state.copyWith(erroGeral: () => null));

  Future<void> salvar() async {
    if (state.salvando || !_validar()) return;
    emit(state.copyWith(salvando: true));

    final tipo = state.tipoPix;
    final resultado = await _repositorio.atualizar(
      nome: state.nome,
      whatsapp: state.whatsapp,
      chavePix: tipo == null ? null : ChavePix.digitada(tipo, state.chavePix),
    );
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(state.copyWith(salvando: false, erroGeral: () => falha.mensagem));
      case Sucesso():
        emit(state.copyWith(salvando: false, salvo: true));
    }
  }

  bool _validar() {
    final erros = (
      nome: Consultora.validarNome(state.nome),
      whatsapp: Consultora.validarWhatsapp(state.whatsapp),
      tipo: ChavePix.erroDoTipo(state.tipoPix, state.chavePix),
      chave: ChavePix.erroDaChave(state.tipoPix, state.chavePix),
    );
    emit(
      state.copyWith(
        erroNome: () => erros.nome,
        erroWhatsapp: () => erros.whatsapp,
        erroTipoPix: () => erros.tipo,
        erroChavePix: () => erros.chave,
      ),
    );
    return erros.nome == null &&
        erros.whatsapp == null &&
        erros.tipo == null &&
        erros.chave == null;
  }
}
