import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/categoria.dart';
import 'package:sou_consultora/core/model/mudanca_foto.dart';
import 'package:sou_consultora/core/model/origem_foto.dart';
import 'package:sou_consultora/core/model/resumo_servico.dart';
import 'package:sou_consultora/core/model/servico.dart';
import 'package:sou_consultora/core/repository/repositorio_categorias.dart';
import 'package:sou_consultora/core/repository/repositorio_servicos.dart';
import 'package:sou_consultora/ui/modules/servicos/formulario/servicos_formulario_state.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

/// Cadastro de serviço: novo ([idServico] nulo) ou edição.
class ServicosFormularioCubit extends Cubit<ServicosFormularioState> {
  ServicosFormularioCubit({
    String? idServico,
    RepositorioServicos? servicos,
    RepositorioCategorias? categorias,
  }) : _servicos = servicos ?? injetor<RepositorioServicos>(),
       _categorias = categorias ?? injetor<RepositorioCategorias>(),
       super(ServicosFormularioState(idServico: idServico)) {
    carregar();
  }

  final RepositorioServicos _servicos;
  final RepositorioCategorias _categorias;

  /// Categorias de serviço e, na edição, os dados do serviço.
  Future<void> carregar() async {
    emit(state.copyWith(carregando: true, erroCarregar: () => null));
    final categorias = await _categorias.deServico();
    if (isClosed) return;
    switch (categorias) {
      case Erro(:final falha):
        _falharAoCarregar(falha.mensagem);
        return;
      case Sucesso(:final valor):
        emit(state.copyWith(categorias: valor));
    }
    if (!state.editando) {
      emit(state.copyWith(carregando: false));
      return;
    }
    final resultado = await _servicos.buscarResumo(state.idServico!);
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        _falharAoCarregar(falha.mensagem);
      case Sucesso(valor: null):
        _falharAoCarregar('Serviço não encontrado.');
      case Sucesso(valor: final ResumoServico servico):
        _preencher(servico);
    }
  }

  void alterarNome(String texto) =>
      emit(state.copyWith(nome: texto, erroNome: () => null));

  void alterarCategoria(Categoria categoria) => emit(
    state.copyWith(categoriaId: () => categoria.id, erroCategoria: () => null),
  );

  void alterarPreco(int centavos) =>
      emit(state.copyWith(preco: () => centavos, erroPreco: () => null));

  /// Custo zero conta como "não informado".
  void alterarCusto(int centavos) =>
      emit(state.copyWith(custo: () => centavos == 0 ? null : centavos));

  void alterarDuracao(int? minutos) =>
      emit(state.copyWith(duracaoMinutos: () => minutos));

  void alterarObservacoes(String texto) =>
      emit(state.copyWith(observacoes: texto));

  Future<void> escolherFoto(OrigemFoto origem) async {
    final resultado = await _servicos.escolherFoto(origem);
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(state.copyWith(aviso: () => AvisoToast.erro(falha.mensagem)));
      case Sucesso(valor: null):
        return;
      case Sucesso(:final valor?):
        emit(state.copyWith(fotoNova: () => valor, fotoRemovida: false));
    }
  }

  void removerFoto() => emit(
    state.copyWith(
      fotoNova: () => null,
      fotoRemovida: state.caminhoFotoAtual != null,
    ),
  );

  void limparAviso() => emit(state.copyWith(aviso: () => null));

  Future<void> salvar() async {
    if (state.salvando || !_validar()) return;
    emit(state.copyWith(salvando: true));
    final resultado = await _servicos.salvar(
      Servico(
        nome: state.nome,
        categoriaId: state.categoriaId!,
        precoCobradoCentavos: state.preco!,
        custoMateriaisCentavos: state.custo,
        duracaoMinutos: state.duracaoMinutos,
        observacoes: state.observacoes,
        caminhoFoto: state.caminhoFotoAtual,
      ),
      id: state.idServico,
      foto: _mudancaFoto(),
    );
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(
          state.copyWith(
            salvando: false,
            aviso: () => AvisoToast.erro(falha.mensagem),
          ),
        );
      case Sucesso():
        emit(state.copyWith(salvando: false, salvo: true));
    }
  }

  bool _validar() {
    final erroNome = Servico.validarNome(state.nome);
    final erroCategoria = Servico.validarCategoria(state.categoriaId);
    final erroPreco = Servico.validarPreco(state.preco);
    emit(
      state.copyWith(
        erroNome: () => erroNome,
        erroCategoria: () => erroCategoria,
        erroPreco: () => erroPreco,
      ),
    );
    return erroNome == null && erroCategoria == null && erroPreco == null;
  }

  void _preencher(ResumoServico servico) {
    emit(
      state.copyWith(
        carregando: false,
        nome: servico.nome,
        categoriaId: () => servico.categoriaId,
        preco: () => servico.precoCobrado,
        custo: () => servico.custoMateriais,
        duracaoMinutos: () => servico.duracaoMinutos,
        observacoes: servico.observacoes ?? '',
        caminhoFotoAtual: () => servico.caminhoFoto,
        urlFotoAtual: () => servico.urlFoto,
        versaoPreenchimento: state.versaoPreenchimento + 1,
      ),
    );
  }

  void _falharAoCarregar(String mensagem) =>
      emit(state.copyWith(carregando: false, erroCarregar: () => mensagem));

  MudancaFoto _mudancaFoto() {
    if (state.fotoNova case final bytes?) return TrocarFoto(bytes);
    if (state.fotoRemovida) return const RemoverFoto();
    return const ManterFoto();
  }
}
