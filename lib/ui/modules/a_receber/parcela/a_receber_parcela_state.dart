import 'package:sou_consultora/core/model/detalhe_parcela.dart';

class AReceberParcelaState {
  const AReceberParcelaState({
    required this.hoje,
    this.detalhe,
    this.carregando = true,
    this.erro,
    this.aviso,
    this.cancelando = false,
    this.cancelada = false,
    this.registrando = false,
    this.erroValor,
    this.erroData,
    this.erroPagamento,
  });

  final DateTime hoje;
  final DetalheParcela? detalhe;
  final bool carregando;
  final String? erro;
  final String? aviso;

  /// Cancelando a venda da parcela.
  final bool cancelando;

  /// A venda foi cancelada: a tela fecha.
  final bool cancelada;

  // Folha "Registrar pagamento".
  final bool registrando;
  final String? erroValor;
  final String? erroData;

  /// Erro do servidor ao registrar (ex.: o saldo mudou).
  final String? erroPagamento;

  AReceberParcelaState copyWith({
    DetalheParcela? detalhe,
    bool? carregando,
    String? Function()? erro,
    String? Function()? aviso,
    bool? cancelando,
    bool? cancelada,
    bool? registrando,
    String? Function()? erroValor,
    String? Function()? erroData,
    String? Function()? erroPagamento,
  }) {
    return AReceberParcelaState(
      hoje: hoje,
      detalhe: detalhe ?? this.detalhe,
      carregando: carregando ?? this.carregando,
      erro: erro != null ? erro() : this.erro,
      aviso: aviso != null ? aviso() : this.aviso,
      cancelando: cancelando ?? this.cancelando,
      cancelada: cancelada ?? this.cancelada,
      registrando: registrando ?? this.registrando,
      erroValor: erroValor != null ? erroValor() : this.erroValor,
      erroData: erroData != null ? erroData() : this.erroData,
      erroPagamento: erroPagamento != null
          ? erroPagamento()
          : this.erroPagamento,
    );
  }
}
