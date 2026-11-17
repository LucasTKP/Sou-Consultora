import 'package:sou_consultora/core/model/filtro_fornecedores.dart';
import 'package:sou_consultora/core/model/ordem_nome.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';

enum CarregamentoFornecedores { carregando, pronto, erro }

class FornecedoresListaState {
  const FornecedoresListaState({
    this.carregamento = CarregamentoFornecedores.carregando,
    this.todos = const [],
    this.status = StatusFiltroFornecedor.todos,
    this.busca = '',
    this.ordem = OrdemNome.aZ,
    this.mensagemErro,
  });

  final CarregamentoFornecedores carregamento;

  /// Todos os fornecedores da consultora (sem filtro).
  final List<ResumoFornecedor> todos;
  final StatusFiltroFornecedor status;
  final String busca;
  final OrdemNome ordem;
  final String? mensagemErro;

  /// Fornecedores exibidos, já filtrados, buscados e ordenados.
  List<ResumoFornecedor> get visiveis => FiltroFornecedores.aplicar(
    todos,
    status: status,
    busca: busca,
    ordem: ordem,
  );

  Map<StatusFiltroFornecedor, int> get contagens =>
      FiltroFornecedores.contagens(todos);

  FornecedoresListaState copyWith({
    CarregamentoFornecedores? carregamento,
    List<ResumoFornecedor>? todos,
    StatusFiltroFornecedor? status,
    String? busca,
    OrdemNome? ordem,
    String? Function()? mensagemErro,
  }) {
    return FornecedoresListaState(
      carregamento: carregamento ?? this.carregamento,
      todos: todos ?? this.todos,
      status: status ?? this.status,
      busca: busca ?? this.busca,
      ordem: ordem ?? this.ordem,
      mensagemErro: mensagemErro != null ? mensagemErro() : this.mensagemErro,
    );
  }
}
