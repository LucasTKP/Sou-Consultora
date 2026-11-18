import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/dto/lembrete_recompra_dto.dart';
import 'package:sou_consultora/core/erros/mapeador_falhas.dart';
import 'package:sou_consultora/core/erros/resultado.dart';

/// Acesso à view `lembretes_recompra` (os outros números do Início vêm dos
/// services de vendas, recebimentos e boletos).
class ServicoInicio {
  ServicoInicio({required this._api});

  final ApiSupabase _api;

  Future<Resultado<List<LembreteRecompraDto>>> listarLembretes() {
    return executarComFalha(() async {
      final linhas = await _api.listar('lembretes_recompra');
      return linhas.map(LembreteRecompraDto.fromJson).toList();
    }, mensagemPadrao: 'Não foi possível carregar os lembretes de recompra.');
  }
}
