import 'package:sou_consultora/core/model/detalhe_parcela.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

class AReceberParcelaState {
  const AReceberParcelaState({
    required this.hoje,
    this.detalhe,
    this.carregando = true,
    this.erro,
    this.aviso,
    this.registrando = false,
    this.erroValor,
    this.erroData,
    this.erroPagamento,
    this.erroParcelas,
  });

  final DateTime hoje;
  final DetalheParcela? detalhe;
  final bool carregando;
  final String? erro;
  final AvisoToast? aviso;

  // Folha "Registrar pagamento".
  final bool registrando;
  final String? erroValor;
  final String? erroData;

  /// Erro do servidor ao registrar (ex.: o saldo mudou).
  final String? erroPagamento;

  /// Erro ao salvar o cronograma das parcelas (folha Editar parcelas).
  final String? erroParcelas;

  AReceberParcelaState copyWith({
    DetalheParcela? detalhe,
    bool? carregando,
    String? Function()? erro,
    AvisoToast? Function()? aviso,
    bool? registrando,
    String? Function()? erroValor,
    String? Function()? erroData,
    String? Function()? erroPagamento,
    String? Function()? erroParcelas,
  }) {
    return AReceberParcelaState(
      hoje: hoje,
      detalhe: detalhe ?? this.detalhe,
      carregando: carregando ?? this.carregando,
      erro: erro != null ? erro() : this.erro,
      aviso: aviso != null ? aviso() : this.aviso,
      registrando: registrando ?? this.registrando,
      erroValor: erroValor != null ? erroValor() : this.erroValor,
      erroData: erroData != null ? erroData() : this.erroData,
      erroPagamento: erroPagamento != null
          ? erroPagamento()
          : this.erroPagamento,
      erroParcelas: erroParcelas != null ? erroParcelas() : this.erroParcelas,
    );
  }
}
