import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/versao_app.dart';
import 'package:sou_consultora/core/model/versoes_minimas.dart';

/// Versão instalada e plataforma do aparelho.
class InfoApp {
  const InfoApp({required this.versao, required this.plataforma});

  final VersaoApp versao;

  /// Null fora de Android/iOS (ex.: desktop em desenvolvimento).
  final PlataformaApp? plataforma;
}

abstract interface class ServicoInfoApp {
  Future<Resultado<InfoApp>> ler();
}

class ServicoInfoAppNativo implements ServicoInfoApp {
  @override
  Future<Resultado<InfoApp>> ler() async {
    try {
      final pacote = await PackageInfo.fromPlatform();
      final versao = VersaoApp.tentarLer(pacote.version);
      if (versao == null) {
        return Erro(const FalhaInesperada('Versão do app ilegível.'));
      }
      final plataforma = switch (defaultTargetPlatform) {
        TargetPlatform.android => PlataformaApp.android,
        TargetPlatform.iOS => PlataformaApp.ios,
        _ => null,
      };
      return Sucesso(InfoApp(versao: versao, plataforma: plataforma));
    } catch (erro, pilha) {
      return Erro(
        const FalhaInesperada('Não foi possível ler a versão do app.'),
        causa: erro,
        pilha: pilha,
      );
    }
  }
}
