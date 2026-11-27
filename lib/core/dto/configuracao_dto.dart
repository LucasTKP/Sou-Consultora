import 'package:sou_consultora/core/model/versao_app.dart';
import 'package:sou_consultora/core/model/versoes_minimas.dart';

/// Espelho da tabela `configuracoes` (chave/valor).
class ConfiguracaoDto {
  const ConfiguracaoDto({required this.chave, required this.valor});

  factory ConfiguracaoDto.fromJson(Map<String, dynamic> json) {
    return ConfiguracaoDto(
      chave: json['chave'] as String,
      valor: json['valor'] as String,
    );
  }

  static const chaveVersaoMinimaAndroid = 'versao_minima_android';
  static const chaveVersaoMinimaIos = 'versao_minima_ios';

  final String chave;
  final String valor;
}

extension ConfiguracoesDto on List<ConfiguracaoDto> {
  /// Valor ilegível vira "sem exigência" (nunca bloqueia por erro de digitação).
  VersoesMinimas paraVersoesMinimas() {
    VersaoApp? ler(String chave) {
      for (final item in this) {
        if (item.chave == chave) return VersaoApp.tentarLer(item.valor);
      }
      return null;
    }

    return VersoesMinimas(
      android: ler(ConfiguracaoDto.chaveVersaoMinimaAndroid),
      ios: ler(ConfiguracaoDto.chaveVersaoMinimaIos),
    );
  }
}
