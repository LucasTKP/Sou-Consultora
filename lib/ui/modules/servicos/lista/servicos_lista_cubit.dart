import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/categoria.dart';
import 'package:sou_consultora/core/model/ordem_nome.dart';
import 'package:sou_consultora/core/model/resumo_servico.dart';
import 'package:sou_consultora/core/repository/repositorio_servicos.dart';
import 'package:sou_consultora/ui/modules/servicos/lista/servicos_lista_state.dart';

/// Lista de serviços: carrega, acompanha as alterações do repositório e
/// guarda busca, filtro e ordem escolhidos na tela.
class ServicosListaCubit extends Cubit<ServicosListaState> {
  ServicosListaCubit({RepositorioServicos? repositorio})
    : _repositorio = repositorio ?? injetor<RepositorioServicos>(),
      super(const ServicosListaState()) {
    final emCache = _repositorio.lista;
    if (emCache != null) _aoMudarLista(emCache);
    _assinatura = _repositorio.mudancas.listen(_aoMudarLista);
    carregar();
  }

  final RepositorioServicos _repositorio;
  late final StreamSubscription<List<ResumoServico>> _assinatura;

  Future<void> carregar() async {
    if (state.carregamento != CarregamentoServicos.pronto) {
      emit(state.copyWith(carregamento: CarregamentoServicos.carregando));
    }
    final resultado = await _repositorio.carregar();
    if (isClosed) return;
    // O sucesso chega pelo stream; aqui só trata a falha.
    if (resultado case Erro(:final falha)) _aoFalhar(falha.mensagem);
  }

  void alterarBusca(String busca) => emit(state.copyWith(busca: busca));

  /// Nula = todas as categorias.
  void alterarCategoria(Categoria? categoria) =>
      emit(state.copyWith(categoria: () => categoria));

  void alterarOrdem(OrdemNome ordem) => emit(state.copyWith(ordem: ordem));

  void inverterOrdem() => emit(state.copyWith(ordem: state.ordem.inversa));

  void _aoMudarLista(List<ResumoServico> lista) {
    if (isClosed) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoServicos.pronto,
        todos: lista,
        mensagemErro: () => null,
      ),
    );
  }

  /// Com lista já na tela, a falha de uma recarga não apaga o que está visível.
  void _aoFalhar(String mensagem) {
    if (state.carregamento == CarregamentoServicos.pronto) return;
    emit(
      state.copyWith(
        carregamento: CarregamentoServicos.erro,
        mensagemErro: () => mensagem,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _assinatura.cancel();
    return super.close();
  }
}
