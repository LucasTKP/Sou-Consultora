import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/dto/categoria_dto.dart';
import 'package:sou_consultora/core/erros/mapeador_falhas.dart';
import 'package:sou_consultora/core/erros/resultado.dart';

/// Leitura de `categorias` (as padrão são copiadas no cadastro da consultora).
class ServicoCategorias {
  ServicoCategorias({required this._api});

  final ApiSupabase _api;

  /// Categorias do tipo produto, em ordem alfabética.
  Future<Resultado<List<CategoriaDto>>> listarDeProduto() => _listar('produto');

  /// Categorias do tipo serviço, em ordem alfabética.
  Future<Resultado<List<CategoriaDto>>> listarDeServico() => _listar('servico');

  Future<Resultado<List<CategoriaDto>>> _listar(String tipo) {
    return executarComFalha(() async {
      final linhas = await _api.listar(
        'categorias',
        ordenarPor: 'nome',
        onde: {'tipo': tipo},
      );
      return linhas.map(CategoriaDto.fromJson).toList();
    }, mensagemPadrao: 'Não foi possível carregar as categorias.');
  }
}
