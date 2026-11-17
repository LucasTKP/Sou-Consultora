import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/resumo_consultora.dart';
import 'package:sou_consultora/core/service/servico_autenticacao.dart';

/// Fachada de autenticação para os Cubits e para a navegação.
class RepositorioAutenticacao {
  RepositorioAutenticacao({required this._servico});

  final ServicoAutenticacao _servico;

  /// Sessão ativa no aparelho neste momento.
  bool get estaLogado => _servico.estaLogado;

  /// Emite a cada entrada, saída ou expiração de sessão.
  Stream<bool> get sessaoAtiva => _servico.sessaoAtiva;

  Future<Resultado<void>> continuarComGoogle() async {
    final resultado = await _servico.entrarComGoogle();
    return switch (resultado) {
      Sucesso() => const Sucesso(null),
      Erro(:final falha) => Erro(falha),
    };
  }

  Future<Resultado<void>> continuarComApple() async {
    final resultado = await _servico.entrarComApple();
    return switch (resultado) {
      Sucesso() => const Sucesso(null),
      Erro(:final falha) => Erro(falha),
    };
  }

  Future<Resultado<void>> sair() => _servico.sair();

  /// Nome e foto da consultora logada.
  ///
  /// Por enquanto vem dos metadados do Google/Apple; a Fase 1 passa a ler
  /// da tabela `consultoras` sem mudar este contrato.
  ResumoConsultora resumoDaConsultora() {
    final usuario = _servico.usuarioAtual;
    final dados = usuario?.userMetadata ?? const <String, dynamic>{};
    return ResumoConsultora.de(
      nome: (dados['full_name'] ?? dados['name']) as String?,
      email: usuario?.email,
      fotoUrl: (dados['avatar_url'] ?? dados['picture']) as String?,
    );
  }
}
