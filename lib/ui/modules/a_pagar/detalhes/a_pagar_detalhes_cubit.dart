import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/core/repository/repositorio_boletos.dart';
import 'package:sou_consultora/core/model/arquivo_comprovante.dart';
import 'package:sou_consultora/ui/modules/a_pagar/detalhes/a_pagar_detalhes_state.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

/// Detalhes do boleto: pagar (com a data), desfazer, comprovante e excluir.
class APagarDetalhesCubit extends Cubit<APagarDetalhesState> {
  APagarDetalhesCubit({
    required this.idBoleto,
    RepositorioBoletos? repositorio,
    DateTime Function()? agora,
  }) : _repositorio = repositorio ?? injetor<RepositorioBoletos>(),
       _agora = agora ?? DateTime.now,
       super(APagarDetalhesState(hoje: (agora ?? DateTime.now)())) {
    final emCache = _repositorio.emCache(idBoleto);
    if (emCache != null) {
      emit(state.copyWith(boleto: emCache, carregando: false));
    }
    carregar();
  }

  final String idBoleto;
  final RepositorioBoletos _repositorio;
  final DateTime Function() _agora;

  Future<void> carregar() async {
    if (state.boleto == null) {
      emit(state.copyWith(carregando: true, erro: () => null));
    }
    final resultado = await _repositorio.buscar(idBoleto);
    if (isClosed) return;
    switch (resultado) {
      case Sucesso(valor: final ResumoBoleto boleto):
        emit(
          state.copyWith(boleto: boleto, carregando: false, erro: () => null),
        );
      case Sucesso(valor: null):
        emit(
          state.copyWith(
            carregando: false,
            erro: () => 'Boleto não encontrado.',
          ),
        );
      case Erro(:final falha):
        _aoFalharCarregar(falha.mensagem);
    }
  }

  /// Limpa os erros da folha ao abri-la de novo.
  void prepararPagamento() => emit(
    state.copyWith(erroDataPagamento: () => null, erroPagamento: () => null),
  );

  /// Valida a data e quita o boleto. True quando gravou (a folha fecha).
  Future<bool> pagar(DateTime? data) async {
    if (state.ocupado) return false;
    final erroData = ResumoBoleto.validarDataPagamento(data, hoje: _agora());
    emit(
      state.copyWith(
        erroDataPagamento: () => erroData,
        erroPagamento: () => null,
      ),
    );
    if (erroData != null) return false;

    emit(state.copyWith(acao: AcaoBoleto.pagando));
    final resultado = await _repositorio.pagar(idBoleto, data!);
    if (isClosed) return false;
    if (resultado case Erro(:final falha)) {
      emit(
        state.copyWith(
          acao: AcaoBoleto.nenhuma,
          erroPagamento: () => falha.mensagem,
        ),
      );
      return false;
    }
    emit(
      state.copyWith(
        acao: AcaoBoleto.nenhuma,
        aviso: () => const AvisoToast.sucesso('Pagamento confirmado.'),
      ),
    );
    await carregar();
    return true;
  }

  Future<void> desfazerPagamento() => _executar(
    AcaoBoleto.desfazendo,
    () => _repositorio.desfazerPagamento(idBoleto),
    sucesso: 'Pagamento desfeito.',
  );

  Future<void> excluir() async {
    final boleto = state.boleto;
    if (boleto == null || state.ocupado) return;
    emit(state.copyWith(acao: AcaoBoleto.excluindo));
    final resultado = await _repositorio.excluir(boleto);
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(
          state.copyWith(
            acao: AcaoBoleto.nenhuma,
            aviso: () => AvisoToast.erro(falha.mensagem),
          ),
        );
      case Sucesso():
        emit(state.copyWith(acao: AcaoBoleto.nenhuma, excluido: true));
    }
  }

  /// Escolhe a foto ou o PDF e anexa (substitui o anterior).
  Future<void> anexarComprovante(OrigemComprovante origem) async {
    final boleto = state.boleto;
    if (boleto == null || state.ocupado) return;
    final escolha = await _repositorio.escolherComprovante(origem);
    if (isClosed) return;
    switch (escolha) {
      case Erro(:final falha):
        emit(state.copyWith(aviso: () => AvisoToast.erro(falha.mensagem)));
      case Sucesso(valor: null):
        return;
      case Sucesso(valor: final arquivo?):
        await _executar(
          AcaoBoleto.anexando,
          () => _repositorio.anexarComprovante(boleto, arquivo),
          sucesso: 'Comprovante anexado.',
        );
    }
  }

  Future<void> verComprovante() async {
    final caminho = state.boleto?.caminhoComprovante;
    if (caminho == null || state.ocupado) return;
    emit(state.copyWith(acao: AcaoBoleto.abrindo));
    final resultado = await _repositorio.abrirComprovante(caminho);
    if (isClosed) return;
    emit(
      state.copyWith(
        acao: AcaoBoleto.nenhuma,
        aviso: () => switch (resultado) {
          Erro(:final falha) => AvisoToast.erro(falha.mensagem),
          Sucesso() => null,
        },
      ),
    );
  }

  void limparAviso() => emit(state.copyWith(aviso: () => null));

  /// Roda a gravação [acao], avisa o resultado e recarrega o boleto.
  Future<void> _executar(
    AcaoBoleto acao,
    Future<Resultado<Object?>> Function() gravar, {
    required String sucesso,
  }) async {
    if (state.ocupado) return;
    emit(state.copyWith(acao: acao));
    final resultado = await gravar();
    if (isClosed) return;
    emit(
      state.copyWith(
        acao: AcaoBoleto.nenhuma,
        aviso: () => switch (resultado) {
          Erro(:final falha) => AvisoToast.erro(falha.mensagem),
          Sucesso() => AvisoToast.sucesso(sucesso),
        },
      ),
    );
    if (resultado is Sucesso) await carregar();
  }

  void _aoFalharCarregar(String mensagem) {
    if (state.boleto != null) {
      emit(state.copyWith(aviso: () => AvisoToast.erro(mensagem)));
      return;
    }
    emit(state.copyWith(carregando: false, erro: () => mensagem));
  }
}
