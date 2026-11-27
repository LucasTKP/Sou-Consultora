import 'dart:typed_data';

import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/dto/catalogo_produto_dto.dart';
import 'package:sou_consultora/core/erros/mapeador_falhas.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/texto_busca.dart';

/// Leitura do catálogo de produtos das marcas (tabela e bucket só de leitura).
class ServicoCatalogo {
  ServicoCatalogo({required this._api});

  static const _tabela = 'catalogo_produtos';
  static const _bucket = 'catalogo';

  final ApiSupabase _api;

  /// Produtos em ordem alfabética, filtrados por [marca] e por [texto]: cada
  /// palavra precisa aparecer no nome ou no código, sem diferenciar acentos nem
  /// maiúsculas (a coluna `busca` do banco já vem normalizada).
  Future<Resultado<List<CatalogoProdutoDto>>> listar({
    String? marca,
    String texto = '',
    int limite = 60,
  }) {
    return executarComFalha(() async {
      final linhas = await _api.listarComBusca(
        _tabela,
        ordenarPor: 'nome',
        onde: {'marca': ?marca},
        contem: {'busca': _palavras(texto)},
        limite: limite,
      );
      return linhas.map(CatalogoProdutoDto.fromJson).toList();
    }, mensagemPadrao: 'Não foi possível carregar o catálogo.');
  }

  /// URLs temporárias das fotos (caminho → URL).
  Future<Resultado<Map<String, String>>> urlsFotos(List<String> caminhos) {
    return executarComFalha(
      () => _api.urlsAssinadas(_bucket, caminhos),
      mensagemPadrao: 'Não foi possível carregar as fotos.',
    );
  }

  Future<Resultado<Uint8List>> baixarFoto(String caminho) {
    return executarComFalha(
      () => _api.baixarArquivo(_bucket, caminho),
      mensagemPadrao: 'Não foi possível baixar a foto do catálogo.',
    );
  }

  static List<String> _palavras(String texto) => [
    for (final palavra in TextoBusca.normalizar(texto).split(' '))
      if (palavra.isNotEmpty) palavra,
  ];
}
