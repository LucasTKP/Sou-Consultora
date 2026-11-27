import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/ui/modules/fornecedores/detalhes/fornecedores_detalhes_state.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

/// Detalhes do fornecedor: mostra o que está em cache e atualiza pela rede.
class FornecedoresDetalhesCubit extends Cubit<FornecedoresDetalhesState> {
  FornecedoresDetalhesCubit({
    required this.idFornecedor,
    RepositorioFornecedores? repositorio,
  }) : _repositorio = repositorio ?? injetor<RepositorioFornecedores>(),
       super(const FornecedoresDetalhesState()) {
    final emCache = _repositorio.resumoEmCache(idFornecedor);
    if (emCache != null) {
      emit(state.copyWith(fornecedor: emCache, carregando: false));
    }
    carregar();
  }

  final String idFornecedor;
  final RepositorioFornecedores _repositorio;

  Future<void> carregar() async {
    if (state.fornecedor == null) {
      emit(state.copyWith(carregando: true, erro: () => null));
    }
    final resultado = await _repositorio.buscarResumo(idFornecedor);
    if (isClosed) return;
    switch (resultado) {
      case Sucesso(valor: final ResumoFornecedor fornecedor):
        emit(
          state.copyWith(
            fornecedor: fornecedor,
            carregando: false,
            erro: () => null,
          ),
        );
      case Sucesso(valor: null):
        emit(
          state.copyWith(
            carregando: false,
            erro: () => 'Fornecedor não encontrado.',
          ),
        );
      case Erro(:final falha):
        _aoFalhar(falha.mensagem);
    }
  }

  Future<void> abrirWhatsapp() async {
    final telefone = state.fornecedor?.telefone;
    if (telefone == null) return;
    final resultado = await _repositorio.abrirWhatsapp(telefone);
    if (isClosed) return;
    if (resultado case Erro(:final falha)) {
      emit(state.copyWith(aviso: () => AvisoToast.erro(falha.mensagem)));
    }
  }

  void limparAviso() => emit(state.copyWith(aviso: () => null));

  /// Com o fornecedor já na tela (cache), a falha da atualização vira aviso.
  void _aoFalhar(String mensagem) {
    if (state.fornecedor != null) {
      emit(state.copyWith(aviso: () => AvisoToast.erro(mensagem)));
      return;
    }
    emit(state.copyWith(carregando: false, erro: () => mensagem));
  }
}
