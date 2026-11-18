import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/detalhe_parcela.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_recebimentos.dart';
import 'package:sou_consultora/ui/formatadores/mensagem_comprovante.dart';
import 'package:sou_consultora/ui/modules/a_receber/comprovante/a_receber_comprovante_state.dart';

/// Comprovante de um pagamento da parcela: carrega e compartilha a imagem.
class AReceberComprovanteCubit extends Cubit<AReceberComprovanteState> {
  AReceberComprovanteCubit({
    required this.idParcela,
    this.idPagamento,
    RepositorioRecebimentos? recebimentos,
    RepositorioConsultora? consultora,
  }) : _recebimentos = recebimentos ?? injetor<RepositorioRecebimentos>(),
       super(
         AReceberComprovanteState(
           consultora: (consultora ?? injetor<RepositorioConsultora>()).atual,
         ),
       ) {
    carregar();
  }

  final String idParcela;

  /// Null = último pagamento da parcela.
  final String? idPagamento;
  final RepositorioRecebimentos _recebimentos;

  Future<void> carregar() async {
    emit(state.copyWith(carregando: true, erro: () => null));
    final resultado = await _recebimentos.detalhe(idParcela);
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(state.copyWith(carregando: false, erro: () => falha.mensagem));
      case Sucesso(valor: null):
        emit(
          state.copyWith(
            carregando: false,
            erro: () => 'Parcela não encontrada.',
          ),
        );
      case Sucesso(valor: final DetalheParcela detalhe):
        _aoCarregar(detalhe);
    }
  }

  /// Abre o compartilhar do celular com a [png] do comprovante e o texto curto.
  Future<void> compartilhar(Uint8List png) async {
    final detalhe = state.detalhe;
    final pagamento = state.pagamento;
    if (detalhe == null || pagamento == null) return;
    emit(state.copyWith(compartilhando: true));
    final resultado = await _recebimentos.compartilharComprovante(
      png: png,
      texto: MensagemComprovante.montar(detalhe: detalhe, pagamento: pagamento),
    );
    if (isClosed) return;
    emit(
      state.copyWith(
        compartilhando: false,
        aviso: () => switch (resultado) {
          Erro(:final falha) => falha.mensagem,
          Sucesso() => null,
        },
      ),
    );
  }

  /// A imagem não pôde ser gerada na tela.
  void falharImagem() => emit(
    state.copyWith(
      compartilhando: false,
      aviso: () => 'Não foi possível gerar a imagem do comprovante.',
    ),
  );

  void limparAviso() => emit(state.copyWith(aviso: () => null));

  void _aoCarregar(DetalheParcela detalhe) {
    final pagamento = detalhe.pagamentoDoComprovante(idPagamento);
    if (pagamento == null) {
      emit(
        state.copyWith(
          carregando: false,
          erro: () => 'Esta parcela ainda não tem pagamento.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(detalhe: detalhe, pagamento: pagamento, carregando: false),
    );
  }
}
