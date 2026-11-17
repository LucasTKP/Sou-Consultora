import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/ui/modules/cadastro/cadastro_state.dart';

/// Ao cadastrar, o repositório publica a consultora e o roteador leva ao Início.
class CadastroCubit extends Cubit<CadastroState> {
  CadastroCubit({
    RepositorioAutenticacao? autenticacao,
    RepositorioConsultora? consultoras,
  }) : this._(
         autenticacao ?? injetor<RepositorioAutenticacao>(),
         consultoras ?? injetor<RepositorioConsultora>(),
       );

  CadastroCubit._(this._autenticacao, this._consultoras)
    : _nomeDoLogin = _nomeUtilizavel(_autenticacao.resumoDaConsultora().nome),
      super(
        CadastroState(
          pedirNome:
              _nomeUtilizavel(_autenticacao.resumoDaConsultora().nome) == null,
        ),
      );

  final RepositorioAutenticacao _autenticacao;
  final RepositorioConsultora _consultoras;
  final String? _nomeDoLogin;

  /// O resumo cai para o e-mail quando não há nome: isso não serve como nome.
  static String? _nomeUtilizavel(String nome) {
    final limpo = nome.trim();
    if (limpo.isEmpty || limpo.contains('@')) return null;
    return limpo;
  }

  void alterarNome(String nome) =>
      emit(state.copyWith(nome: nome, erroNome: () => null));

  void alterarWhatsapp(String whatsapp) =>
      emit(state.copyWith(whatsapp: whatsapp, erroWhatsapp: () => null));

  void limparErroGeral() => emit(state.copyWith(erroGeral: () => null));

  Future<void> continuar() async {
    if (state.salvando || !_validar()) return;
    emit(state.copyWith(salvando: true));

    final nome = state.pedirNome ? state.nome : _nomeDoLogin!;
    final resultado = await _consultoras.cadastrar(
      nome: nome,
      whatsapp: state.whatsapp,
    );
    if (isClosed) return;
    if (resultado case Erro(:final falha)) {
      emit(state.copyWith(salvando: false, erroGeral: () => falha.mensagem));
    }
  }

  /// Voltar no cadastro encerra a sessão (volta ao login).
  Future<void> voltar() => _autenticacao.sair();

  bool _validar() {
    final erroNome = state.pedirNome
        ? Consultora.validarNome(state.nome)
        : null;
    final erroWhatsapp = Consultora.validarWhatsapp(state.whatsapp);
    emit(
      state.copyWith(
        erroNome: () => erroNome,
        erroWhatsapp: () => erroWhatsapp,
      ),
    );
    return erroNome == null && erroWhatsapp == null;
  }
}
