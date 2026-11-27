import 'package:sou_consultora/core/model/versao_app.dart';

/// Plataforma em que o app está instalado.
enum PlataformaApp { android, ios }

/// Versão mínima exigida em cada plataforma (null = sem exigência).
class VersoesMinimas {
  const VersoesMinimas({this.android, this.ios});

  final VersaoApp? android;
  final VersaoApp? ios;

  VersaoApp? paraPlataforma(PlataformaApp plataforma) => switch (plataforma) {
    PlataformaApp.android => android,
    PlataformaApp.ios => ios,
  };

  /// Verdadeiro se [instalada] está abaixo do mínimo da [plataforma].
  bool exigeAtualizacao(VersaoApp instalada, PlataformaApp plataforma) {
    final minima = paraPlataforma(plataforma);
    return minima != null && instalada.abaixoDe(minima);
  }
}
