import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/foundation.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_versao.dart';

/// Situação de acesso ao app (sessão + cadastro da consultora).
enum EstadoAcesso {
  /// Versão instalada abaixo do mínimo exigido: só a tela de atualização.
  atualizacaoObrigatoria,
  desconectado,
  verificando,
  erroVerificacao,
  semCadastro,
  pronto,
}

/// Fonte única da situação de acesso. O roteador escuta este notificador.
///
/// Com [versao], o app confere a versão mínima antes de tudo (até do login);
/// sem ela, a conferência é pulada.
class NotificadorAcesso extends ChangeNotifier {
  NotificadorAcesso({
    required RepositorioAutenticacao autenticacao,
    required this._consultoras,
    RepositorioVersao? versao,
  }) : _autenticacao = autenticacao,
       _estado = versao == null
           ? EstadoAcesso.desconectado
           : EstadoAcesso.verificando {
    _assinaturaSessao = autenticacao.sessaoAtiva.listen(_aoMudarSessao);
    _assinaturaConsultora = _consultoras.mudancas.listen(_aoMudarConsultora);
    if (versao == null) {
      _liberado = true;
      if (autenticacao.estaLogado) _verificar();
    } else {
      _conferirVersao(versao);
    }
  }

  final RepositorioAutenticacao _autenticacao;
  final RepositorioConsultora _consultoras;

  /// Falso enquanto a versão é conferida e quando ela está abaixo do mínimo.
  bool _liberado = false;
  bool _descartado = false;
  late final StreamSubscription<bool> _assinaturaSessao;
  late final StreamSubscription<Consultora?> _assinaturaConsultora;

  EstadoAcesso _estado;
  String? _mensagemErro;

  /// Cada verificação ganha um número; respostas de verificações antigas são ignoradas.
  int _verificacaoAtual = 0;

  EstadoAcesso get estado => _estado;

  /// Mensagem da última falha de verificação.
  String? get mensagemErro => _mensagemErro;

  Future<void> tentarNovamente() async {
    if (_estado != EstadoAcesso.erroVerificacao) return;
    await _verificar();
  }

  /// Falha ao conferir (sem rede, tabela indisponível) libera o app: não
  /// travamos ninguém por causa disso.
  Future<void> _conferirVersao(RepositorioVersao versao) async {
    final resultado = await versao.atualizacaoObrigatoria();
    if (_descartado) return;
    if (resultado case Sucesso(valor: true)) {
      _mudar(EstadoAcesso.atualizacaoObrigatoria);
      return;
    }
    _liberado = true;
    if (_autenticacao.estaLogado) {
      await _verificar();
    } else {
      _mudar(EstadoAcesso.desconectado);
    }
  }

  void _aoMudarSessao(bool logado) {
    if (!_liberado) return;
    if (!logado) {
      _verificacaoAtual++;
      _consultoras.limpar();
      _mudar(EstadoAcesso.desconectado);
      return;
    }
    // Renovação de token também emite "logado": só verifica ao entrar.
    if (_estado == EstadoAcesso.desconectado) _verificar();
  }

  /// O cadastro concluído publica a consultora: libera o app sem nova consulta.
  void _aoMudarConsultora(Consultora? consultora) {
    if (_liberado &&
        consultora != null &&
        _estado == EstadoAcesso.semCadastro) {
      _mudar(EstadoAcesso.pronto);
    }
  }

  Future<void> _verificar() async {
    final numero = ++_verificacaoAtual;
    _mudar(EstadoAcesso.verificando);
    final resultado = await _consultoras.buscarMinha();
    if (numero != _verificacaoAtual) return;

    switch (resultado) {
      case Erro(:final falha):
        _mensagemErro = falha.mensagem;
        _mudar(EstadoAcesso.erroVerificacao);
      case Sucesso(valor: null):
        _mudar(EstadoAcesso.semCadastro);
      case Sucesso():
        _mudar(EstadoAcesso.pronto);
    }
  }

  void _mudar(EstadoAcesso novo) {
    if (novo == _estado) return;
    _estado = novo;
    notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _assinaturaSessao.cancel();
    _assinaturaConsultora.cancel();
    super.dispose();
  }
}
