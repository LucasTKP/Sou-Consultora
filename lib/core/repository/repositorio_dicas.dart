import 'package:sou_consultora/core/api/registro_depuracao.dart';
import 'package:sou_consultora/core/model/dica_app.dart';
import 'package:sou_consultora/core/service/servico_dicas.dart';

/// Decide se uma dica deve aparecer e lembra que ela já foi vista.
///
/// Falha ao ler ou gravar nunca atrapalha o app: sem conseguir ler, a dica não
/// aparece (melhor que repetir a cada abertura).
class RepositorioDicas {
  RepositorioDicas({required this._servico});

  final ServicoDicas _servico;

  /// Verdadeiro só se a consultora ainda não viu a [dica].
  Future<bool> deveMostrar(DicaApp dica) async {
    try {
      return !await _servico.jaViu(dica);
    } catch (erro, pilha) {
      RegistroDepuracao.erro(
        'Ler dica ${dica.chave}',
        causa: erro,
        pilha: pilha,
      );
      return false;
    }
  }

  Future<void> marcarComoVista(DicaApp dica) async {
    try {
      await _servico.marcarComoVista(dica);
    } catch (erro, pilha) {
      RegistroDepuracao.erro(
        'Gravar dica ${dica.chave}',
        causa: erro,
        pilha: pilha,
      );
    }
  }

  /// Para testes e E2E: nenhuma dica atrapalha o fluxo.
  Future<void> marcarTodasComoVistas() async {
    for (final dica in DicaApp.values) {
      await marcarComoVista(dica);
    }
  }
}
