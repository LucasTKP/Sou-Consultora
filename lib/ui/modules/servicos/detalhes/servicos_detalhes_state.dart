import 'package:sou_consultora/core/model/resumo_servico.dart';

class ServicosDetalhesState {
  const ServicosDetalhesState({
    this.servico,
    this.carregando = true,
    this.erro,
    this.aviso,
  });

  final ResumoServico? servico;
  final bool carregando;
  final String? erro;

  /// Mensagem passageira (ex.: falha ao atualizar com o serviço na tela).
  final String? aviso;

  ServicosDetalhesState copyWith({
    ResumoServico? servico,
    bool? carregando,
    String? Function()? erro,
    String? Function()? aviso,
  }) {
    return ServicosDetalhesState(
      servico: servico ?? this.servico,
      carregando: carregando ?? this.carregando,
      erro: erro != null ? erro() : this.erro,
      aviso: aviso != null ? aviso() : this.aviso,
    );
  }
}
