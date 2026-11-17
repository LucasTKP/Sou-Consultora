import 'package:sou_consultora/core/model/categoria.dart';
import 'package:sou_consultora/core/model/ordem_nome.dart';
import 'package:sou_consultora/core/model/resumo_servico.dart';
import 'package:sou_consultora/core/model/texto_busca.dart';

/// Regras de busca, filtro e ordem da lista de serviços (puras, sem Flutter).
abstract final class FiltroServicos {
  /// [categoria] nula = todas.
  static List<ResumoServico> aplicar(
    List<ResumoServico> servicos, {
    required Categoria? categoria,
    required String busca,
    required OrdemNome ordem,
  }) {
    final filtrados =
        servicos
            .where(
              (s) =>
                  (categoria == null || s.categoriaId == categoria.id) &&
                  s.combinaBusca(busca),
            )
            .toList()
          ..sort(
            (a, b) =>
                TextoBusca.normalizar(a.nome)
                    .compareTo(TextoBusca.normalizar(b.nome)),
          );
    return ordem == OrdemNome.aZ ? filtrados : filtrados.reversed.toList();
  }

  /// Categorias que têm serviços, em ordem alfabética, com a quantidade.
  static Map<Categoria, int> contagens(List<ResumoServico> servicos) {
    final contagem = <Categoria, int>{};
    for (final s in servicos) {
      final categoria = Categoria(id: s.categoriaId, nome: s.categoriaNome);
      contagem[categoria] = (contagem[categoria] ?? 0) + 1;
    }
    final ordenadas = contagem.keys.toList()
      ..sort(
        (a, b) =>
            TextoBusca.normalizar(a.nome)
                .compareTo(TextoBusca.normalizar(b.nome)),
      );
    return {for (final c in ordenadas) c: contagem[c]!};
  }
}
