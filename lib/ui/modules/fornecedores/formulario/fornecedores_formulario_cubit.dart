import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/fornecedor.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/ui/formatadores/formatador_telefone.dart';
import 'package:sou_consultora/ui/modules/fornecedores/formulario/fornecedores_formulario_state.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

/// Novo fornecedor ([idFornecedor] nulo) ou edição (com "Em espera").
class FornecedoresFormularioCubit extends Cubit<FornecedoresFormularioState> {
  FornecedoresFormularioCubit({
    String? idFornecedor,
    RepositorioFornecedores? repositorio,
  }) : _repositorio = repositorio ?? injetor<RepositorioFornecedores>(),
       super(
         FornecedoresFormularioState(
           idFornecedor: idFornecedor,
           carregando: idFornecedor != null,
         ),
       ) {
    if (idFornecedor != null) carregar();
  }

  final RepositorioFornecedores _repositorio;

  /// Edição: preenche com os dados atuais do fornecedor.
  Future<void> carregar() async {
    emit(state.copyWith(carregando: true, erroCarregar: () => null));
    final resultado = await _repositorio.buscarResumo(state.idFornecedor!);
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(
          state.copyWith(carregando: false, erroCarregar: () => falha.mensagem),
        );
      case Sucesso(valor: null):
        emit(
          state.copyWith(
            carregando: false,
            erroCarregar: () => 'Fornecedor não encontrado.',
          ),
        );
      case Sucesso(valor: final ResumoFornecedor fornecedor):
        _preencher(fornecedor);
    }
  }

  void alterarNome(String texto) =>
      emit(state.copyWith(nome: texto, erroNome: () => null));

  void alterarRamo(String texto) => emit(state.copyWith(ramo: texto));

  void alterarContato(String texto) => emit(state.copyWith(contato: texto));

  void alterarTelefone(String texto) =>
      emit(state.copyWith(telefone: texto, erroTelefone: () => null));

  void alterarObservacoes(String texto) =>
      emit(state.copyWith(observacoes: texto));

  void alterarEmEspera(bool emEspera) =>
      emit(state.copyWith(emEspera: emEspera));

  void limparAviso() => emit(state.copyWith(aviso: () => null));

  Future<void> salvar() async {
    if (state.salvando || !_validar()) return;

    emit(state.copyWith(salvando: true));
    final resultado = await _repositorio.salvar(
      Fornecedor(
        nome: state.nome,
        ramo: state.ramo,
        contato: state.contato,
        telefone: state.telefone,
        observacoes: state.observacoes,
        // Só a edição muda o status; o novo nasce ativo.
        ativo: !(state.editando && state.emEspera),
      ),
      id: state.idFornecedor,
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
    final erroNome = Fornecedor.validarNome(state.nome);
    final erroTelefone = Fornecedor.validarTelefone(state.telefone);
    emit(
      state.copyWith(
        erroNome: () => erroNome,
        erroTelefone: () => erroTelefone,
      ),
    );
    return erroNome == null && erroTelefone == null;
  }

  void _preencher(ResumoFornecedor fornecedor) {
    final telefone = fornecedor.telefone;
    emit(
      state.copyWith(
        carregando: false,
        nome: fornecedor.nome,
        ramo: fornecedor.ramo ?? '',
        contato: fornecedor.contato ?? '',
        telefone: telefone == null ? '' : FormatadorTelefone.formatar(telefone),
        observacoes: fornecedor.observacoes ?? '',
        emEspera: fornecedor.emEspera,
        versaoPreenchimento: state.versaoPreenchimento + 1,
      ),
    );
  }
}
