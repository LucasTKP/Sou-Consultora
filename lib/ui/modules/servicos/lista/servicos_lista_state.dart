import 'package:sou_consultora/core/model/categoria.dart';
import 'package:sou_consultora/core/model/filtro_servicos.dart';
import 'package:sou_consultora/core/model/ordem_nome.dart';
import 'package:sou_consultora/core/model/resumo_servico.dart';

enum CarregamentoServicos { carregando, pronto, erro }

class ServicosListaState {
  const ServicosListaState({
    this.carregamento = CarregamentoServicos.carregando,
    this.todos = const [],
    this.categoria,
    this.busca = '',
    this.ordem = OrdemNome.aZ,
    this.mensagemErro,
  });

  final CarregamentoServicos carregamento;
  final List<ResumoServico> todos;

  /// Nula = todas as categorias.
  final Categoria? categoria;
  final String busca;
  final OrdemNome ordem;
  final String? mensagemErro;

  List<ResumoServico> get visiveis => FiltroServicos.aplicar(
    todos,
    categoria: categoria,
    busca: busca,
    ordem: ordem,
  );

  Map<Categoria, int> get contagens => FiltroServicos.contagens(todos);

  ServicosListaState copyWith({
    CarregamentoServicos? carregamento,
    List<ResumoServico>? todos,
    Categoria? Function()? categoria,
    String? busca,
    OrdemNome? ordem,
    String? Function()? mensagemErro,
  }) {
    return ServicosListaState(
      carregamento: carregamento ?? this.carregamento,
      todos: todos ?? this.todos,
      categoria: categoria != null ? categoria() : this.categoria,
      busca: busca ?? this.busca,
      ordem: ordem ?? this.ordem,
      mensagemErro: mensagemErro != null ? mensagemErro() : this.mensagemErro,
    );
  }
}
