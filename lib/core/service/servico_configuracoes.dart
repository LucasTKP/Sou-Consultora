import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/dto/configuracao_dto.dart';
import 'package:sou_consultora/core/erros/mapeador_falhas.dart';
import 'package:sou_consultora/core/erros/resultado.dart';

/// Leitura de `configuracoes` (tabela global; legível até sem login).
class ServicoConfiguracoes {
  ServicoConfiguracoes({required this._api});

  final ApiSupabase _api;

  Future<Resultado<List<ConfiguracaoDto>>> listar() {
    return executarComFalha(() async {
      final linhas = await _api.listar('configuracoes');
      return linhas.map(ConfiguracaoDto.fromJson).toList();
    }, mensagemPadrao: 'Não foi possível conferir a versão do app.');
  }
}
