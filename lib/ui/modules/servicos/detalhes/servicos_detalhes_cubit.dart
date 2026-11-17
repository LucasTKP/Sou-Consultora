import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/resumo_servico.dart';
import 'package:sou_consultora/core/repository/repositorio_servicos.dart';
import 'package:sou_consultora/ui/modules/servicos/detalhes/servicos_detalhes_state.dart';

/// Detalhes do serviço: mostra o que está em cache e atualiza pela rede.
class ServicosDetalhesCubit extends Cubit<ServicosDetalhesState> {
  ServicosDetalhesCubit({
    required this.idServico,
    RepositorioServicos? repositorio,
  }) : _repositorio = repositorio ?? injetor<RepositorioServicos>(),
       super(const ServicosDetalhesState()) {
    final emCache = _repositorio.resumoEmCache(idServico);
    if (emCache != null) {
      emit(state.copyWith(servico: emCache, carregando: false));
    }
    carregar();
  }

  final String idServico;
  final RepositorioServicos _repositorio;

  Future<void> carregar() async {
    if (state.servico == null) {
      emit(state.copyWith(carregando: true, erro: () => null));
    }
    final resultado = await _repositorio.buscarResumo(idServico);
    if (isClosed) return;
    switch (resultado) {
      case Sucesso(valor: final ResumoServico servico):
        emit(
          state.copyWith(servico: servico, carregando: false, erro: () => null),
        );
      case Sucesso(valor: null):
        emit(
          state.copyWith(
            carregando: false,
            erro: () => 'Serviço não encontrado.',
          ),
        );
      case Erro(:final falha):
        _aoFalhar(falha.mensagem);
    }
  }

  void limparAviso() => emit(state.copyWith(aviso: () => null));

  void _aoFalhar(String mensagem) {
    if (state.servico != null) {
      emit(state.copyWith(aviso: () => mensagem));
      return;
    }
    emit(state.copyWith(carregando: false, erro: () => mensagem));
  }
}
