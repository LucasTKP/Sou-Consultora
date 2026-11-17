import 'package:sou_consultora/core/model/resumo_cliente.dart';

class ClientesDetalhesState {
  const ClientesDetalhesState({
    required this.hoje,
    this.resumo,
    this.carregando = false,
    this.erro,
  });

  final DateTime hoje;
  final ResumoCliente? resumo;
  final bool carregando;
  final String? erro;

  ClientesDetalhesState copyWith({
    ResumoCliente? resumo,
    bool? carregando,
    String? Function()? erro,
  }) {
    return ClientesDetalhesState(
      hoje: hoje,
      resumo: resumo ?? this.resumo,
      carregando: carregando ?? this.carregando,
      erro: erro != null ? erro() : this.erro,
    );
  }
}
