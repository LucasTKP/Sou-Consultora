import 'package:sou_consultora/core/model/ordem_nome.dart';
import 'package:sou_consultora/core/model/resumo_cliente.dart';
import 'package:sou_consultora/core/model/texto_busca.dart';

/// Opções do filtro de status da lista de clientes.
enum StatusFiltroCliente {
  todos('Todos os clientes'),
  emDia('Em dia'),
  comSaldo('Com saldo'),
  aniversariantes('Aniversariantes');

  const StatusFiltroCliente(this.rotulo);

  final String rotulo;

  bool aceita(ResumoCliente cliente, DateTime hoje) {
    return switch (this) {
      todos => true,
      // Parcelas futuras não tiram a cliente de "em dia"; só o atraso.
      emDia => cliente.valorAtrasado == 0,
      comSaldo => cliente.comSaldo,
      aniversariantes => cliente.aniversarianteNoMes(hoje),
    };
  }
}

/// Regras de busca, filtro e ordem da lista de clientes (puras, sem Flutter).
abstract final class FiltroClientes {
  static List<ResumoCliente> aplicar(
    List<ResumoCliente> clientes, {
    required StatusFiltroCliente status,
    required String busca,
    required OrdemNome ordem,
    required DateTime hoje,
  }) {
    final filtradas =
        clientes
            .where((c) => status.aceita(c, hoje) && c.combinaBusca(busca))
            .toList()
          ..sort(
            (a, b) =>
                TextoBusca.normalizar(a.nome)
                    .compareTo(TextoBusca.normalizar(b.nome)),
          );
    return ordem == OrdemNome.aZ ? filtradas : filtradas.reversed.toList();
  }

  /// Quantidade de clientes em cada opção do filtro (ignora a busca).
  static Map<StatusFiltroCliente, int> contagens(
    List<ResumoCliente> clientes,
    DateTime hoje,
  ) {
    return {
      for (final status in StatusFiltroCliente.values)
        status: clientes.where((c) => status.aceita(c, hoje)).length,
    };
  }
}
