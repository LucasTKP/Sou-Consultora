import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/versoes_minimas.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_suporte.dart';
import 'package:sou_consultora/core/repository/repositorio_versao.dart';
import 'package:sou_consultora/ui/formatadores/mensagem_suporte.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_suporte/botao_suporte_state.dart';

/// Abre o WhatsApp do suporte com nome, versão do app e o erro da tela.
class BotaoSuporteCubit extends Cubit<BotaoSuporteState> {
  /// As dependências só são resolvidas ao tocar no botão: a tela de erro aparece
  /// justamente quando algo falhou e não deve depender delas para ser montada.
  BotaoSuporteCubit({
    RepositorioSuporte? suporte,
    RepositorioConsultora? consultora,
    RepositorioVersao? versao,
  }) : _suporte = suporte,
       _consultora = consultora,
       _versao = versao,
       super(const BotaoSuporteState());

  final RepositorioSuporte? _suporte;
  final RepositorioConsultora? _consultora;
  final RepositorioVersao? _versao;

  /// [detalhe] é o texto do erro que a consultora está vendo.
  Future<void> abrir({String? detalhe}) async {
    if (state.abrindo) return;
    emit(const BotaoSuporteState(abrindo: true));

    final suporte = _suporte ?? injetor<RepositorioSuporte>();
    final consultora = _consultora ?? injetor<RepositorioConsultora>();
    final repositorioVersao =
        _versao ??
        (injetor.isRegistered<RepositorioVersao>()
            ? injetor<RepositorioVersao>()
            : null);

    String? versao;
    PlataformaApp? plataforma;
    if (await repositorioVersao?.instalada() case Sucesso(:final valor)) {
      versao = valor.versao.toString();
      plataforma = valor.plataforma;
    }

    final resultado = await suporte.abrirConversa(
      MensagemSuporte.montar(
        nomeConsultora: consultora.atual?.nome ?? '',
        versao: versao,
        plataforma: plataforma,
        detalhe: detalhe,
      ),
    );
    if (isClosed) return;
    emit(
      BotaoSuporteState(
        erro: resultado is Erro<void> ? resultado.falha.mensagem : null,
      ),
    );
  }

  void limparErro() => emit(const BotaoSuporteState());
}
