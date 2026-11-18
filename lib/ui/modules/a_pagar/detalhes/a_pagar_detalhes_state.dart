import 'package:sou_consultora/core/model/boleto.dart';

/// O que está em andamento na tela (desabilita os botões e muda o texto).
enum AcaoBoleto { nenhuma, pagando, desfazendo, excluindo, anexando, abrindo }

class APagarDetalhesState {
  const APagarDetalhesState({
    required this.hoje,
    this.boleto,
    this.carregando = true,
    this.erro,
    this.aviso,
    this.acao = AcaoBoleto.nenhuma,
    this.excluido = false,
    this.erroDataPagamento,
    this.erroPagamento,
  });

  final DateTime hoje;
  final ResumoBoleto? boleto;
  final bool carregando;
  final String? erro;
  final String? aviso;
  final AcaoBoleto acao;

  /// O boleto foi excluído: a tela fecha.
  final bool excluido;

  // Folha "Confirmar pagamento".
  final String? erroDataPagamento;

  /// Erro do servidor ao pagar (ex.: data futura recusada pelo banco).
  final String? erroPagamento;

  bool get ocupado => acao != AcaoBoleto.nenhuma;

  APagarDetalhesState copyWith({
    ResumoBoleto? boleto,
    bool? carregando,
    String? Function()? erro,
    String? Function()? aviso,
    AcaoBoleto? acao,
    bool? excluido,
    String? Function()? erroDataPagamento,
    String? Function()? erroPagamento,
  }) {
    return APagarDetalhesState(
      hoje: hoje,
      boleto: boleto ?? this.boleto,
      carregando: carregando ?? this.carregando,
      erro: erro != null ? erro() : this.erro,
      aviso: aviso != null ? aviso() : this.aviso,
      acao: acao ?? this.acao,
      excluido: excluido ?? this.excluido,
      erroDataPagamento: erroDataPagamento != null
          ? erroDataPagamento()
          : this.erroDataPagamento,
      erroPagamento: erroPagamento != null
          ? erroPagamento()
          : this.erroPagamento,
    );
  }
}
