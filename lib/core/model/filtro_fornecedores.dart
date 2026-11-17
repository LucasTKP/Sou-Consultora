import 'package:sou_consultora/core/model/ordem_nome.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';
import 'package:sou_consultora/core/model/texto_busca.dart';

/// Opções do filtro de status da lista de fornecedores.
enum StatusFiltroFornecedor {
  todos('Todos os status'),
  ativos('Ativos'),
  emEspera('Em espera'),
  venceHoje('Vence hoje');

  const StatusFiltroFornecedor(this.rotulo);

  final String rotulo;

  bool aceita(ResumoFornecedor fornecedor) {
    return switch (this) {
      todos => true,
      ativos => fornecedor.ativo,
      emEspera => fornecedor.emEspera,
      // Inclui quem está em espera: o boleto vence do mesmo jeito.
      venceHoje => fornecedor.venceHoje,
    };
  }
}

/// Regras de busca, filtro e ordem da lista de fornecedores (puras, sem Flutter).
abstract final class FiltroFornecedores {
  static List<ResumoFornecedor> aplicar(
    List<ResumoFornecedor> fornecedores, {
    required StatusFiltroFornecedor status,
    required String busca,
    required OrdemNome ordem,
  }) {
    final filtrados =
        fornecedores
            .where((f) => status.aceita(f) && f.combinaBusca(busca))
            .toList()
          ..sort(
            (a, b) =>
                TextoBusca.normalizar(a.nome)
                    .compareTo(TextoBusca.normalizar(b.nome)),
          );
    return ordem == OrdemNome.aZ ? filtrados : filtrados.reversed.toList();
  }

  /// Quantidade de fornecedores em cada opção do filtro (ignora a busca).
  static Map<StatusFiltroFornecedor, int> contagens(
    List<ResumoFornecedor> fornecedores,
  ) {
    return {
      for (final status in StatusFiltroFornecedor.values)
        status: fornecedores.where(status.aceita).length,
    };
  }
}
