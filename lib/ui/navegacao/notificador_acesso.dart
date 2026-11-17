import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/foundation.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';

/// Situação de acesso ao app (sessão + cadastro da consultora).
enum EstadoAcesso {
  desconectado,
  verificando,
  erroVerificacao,
  semCadastro,
  pronto,
}

/// Fonte única da situação de acesso. O roteador escuta este notificador.
class NotificadorAcesso extends ChangeNotifier {
  NotificadorAcesso({
    required RepositorioAutenticacao autenticacao,
    required this._consultoras,
  }) : _estado = EstadoAcesso.desconectado {
    _assinaturaSessao = autenticacao.sessaoAtiva.listen(_aoMudarSessao);
    _assinaturaConsultora = _consultoras.mudancas.listen(_aoMudarConsultora);
    if (autenticacao.estaLogado) _verificar();
  }

  final RepositorioConsultora _consultoras;
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

  void _aoMudarSessao(bool logado) {
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
    if (consultora != null && _estado == EstadoAcesso.semCadastro) {
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
    _assinaturaSessao.cancel();
    _assinaturaConsultora.cancel();
    super.dispose();
  }
}
