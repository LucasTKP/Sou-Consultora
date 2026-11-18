import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/core/model/filtro_boletos.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';

enum CarregamentoBoletos { carregando, pronto, erro }

class APagarListaState {
  const APagarListaState({
    required this.hoje,
    required this.mes,
    this.fornecedorId,
    this.carregamento = CarregamentoBoletos.carregando,
    this.todos = const [],
    this.status = StatusFiltroBoleto.todos,
    this.busca = '',
    this.mensagemErro,
  });

  final DateTime hoje;

  /// Só os boletos desta marca (lista aberta por Fornecedores).
  final String? fornecedorId;
  final CarregamentoBoletos carregamento;
  final List<ResumoBoleto> todos;
  final StatusFiltroBoleto status;

  /// Null = todos os meses (pelo vencimento).
  final MesAno? mes;
  final String busca;
  final String? mensagemErro;

  List<ResumoBoleto> get visiveis => FiltroBoletos.aplicar(
    todos,
    status: status,
    mes: mes,
    busca: busca,
    hoje: hoje,
    fornecedorId: fornecedorId,
  );

  Map<StatusFiltroBoleto, int> get contagens => FiltroBoletos.contagens(
    todos,
    mes: mes,
    hoje: hoje,
    fornecedorId: fornecedorId,
  );

  List<MesAno> get meses => FiltroBoletos.meses(todos, hoje: hoje);

  /// Nome da marca filtrada (do primeiro boleto dela), para o cabeçalho.
  String? get nomeFornecedor {
    final id = fornecedorId;
    if (id == null) return null;
    for (final boleto in todos) {
      if (boleto.fornecedorId == id) return boleto.fornecedorNome;
    }
    return null;
  }

  APagarListaState copyWith({
    CarregamentoBoletos? carregamento,
    List<ResumoBoleto>? todos,
    StatusFiltroBoleto? status,
    MesAno? Function()? mes,
    String? busca,
    String? Function()? mensagemErro,
  }) {
    return APagarListaState(
      hoje: hoje,
      fornecedorId: fornecedorId,
      carregamento: carregamento ?? this.carregamento,
      todos: todos ?? this.todos,
      status: status ?? this.status,
      mes: mes != null ? mes() : this.mes,
      busca: busca ?? this.busca,
      mensagemErro: mensagemErro != null ? mensagemErro() : this.mensagemErro,
    );
  }
}
