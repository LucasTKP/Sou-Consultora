import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre um link fora do app (ex.: comprovante em PDF ou foto por URL assinada).
abstract interface class ServicoAbrirLink {
  Future<Resultado<void>> abrir(String url);
}

class ServicoAbrirLinkNativo implements ServicoAbrirLink {
  static const _falha = FalhaInesperada('Não foi possível abrir o arquivo.');

  @override
  Future<Resultado<void>> abrir(String url) async {
    try {
      final abriu = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      return abriu ? const Sucesso(null) : Erro(_falha);
    } catch (erro, pilha) {
      return Erro(_falha, causa: erro, pilha: pilha);
    }
  }
}
