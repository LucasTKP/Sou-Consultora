import 'package:sou_consultora/core/dto/configuracao_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/versoes_minimas.dart';
import 'package:sou_consultora/core/service/servico_abrir_link.dart';
import 'package:sou_consultora/core/service/servico_configuracoes.dart';
import 'package:sou_consultora/core/service/servico_info_app.dart';

/// Confere se a versão instalada atende ao mínimo exigido no banco e abre a loja.
class RepositorioVersao {
  RepositorioVersao({
    required this._configuracoes,
    required this._infoApp,
    required this._abrirLink,
    required this._urlLojaAndroid,
    required this._urlLojaIos,
  });

  final ServicoConfiguracoes _configuracoes;
  final ServicoInfoApp _infoApp;
  final ServicoAbrirLink _abrirLink;
  final String _urlLojaAndroid;
  final String _urlLojaIos;

  PlataformaApp? _plataforma;

  /// `true` = a versão instalada está abaixo do mínimo e o app deve bloquear.
  ///
  /// Falha ao conferir (rede, tabela indisponível) devolve [Erro]; quem chama
  /// decide se libera (o app libera, para não travar ninguém por falha de rede).
  Future<Resultado<bool>> atualizacaoObrigatoria() async {
    switch (await _infoApp.ler()) {
      case Erro(:final falha):
        return Erro(falha);
      case Sucesso(:final valor):
        return _conferir(valor);
    }
  }

  Future<Resultado<bool>> _conferir(InfoApp instalada) async {
    final plataforma = _plataforma = instalada.plataforma;
    if (plataforma == null) return const Sucesso(false);

    return switch (await _configuracoes.listar()) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(
        valor.paraVersoesMinimas().exigeAtualizacao(
          instalada.versao,
          plataforma,
        ),
      ),
    };
  }

  /// Versão e plataforma do app instalado (usado, por exemplo, na mensagem de suporte).
  Future<Resultado<InfoApp>> instalada() => _infoApp.ler();

  /// Abre a página do app na loja da plataforma.
  Future<Resultado<void>> abrirLoja() async {
    final url = switch (_plataforma) {
      PlataformaApp.android => _urlLojaAndroid,
      PlataformaApp.ios => _urlLojaIos,
      null => '',
    };
    if (!Uri.parse(url).hasScheme) {
      return Erro(const FalhaInesperada('Link da loja não configurado.'));
    }
    return _abrirLink.abrir(url);
  }
}
