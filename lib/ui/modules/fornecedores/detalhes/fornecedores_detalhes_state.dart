import 'package:sou_consultora/core/model/resumo_fornecedor.dart';

class FornecedoresDetalhesState {
  const FornecedoresDetalhesState({
    this.fornecedor,
    this.carregando = true,
    this.erro,
    this.aviso,
  });

  final ResumoFornecedor? fornecedor;
  final bool carregando;
  final String? erro;

  /// Mensagem passageira (ex.: WhatsApp não abriu).
  final String? aviso;

  FornecedoresDetalhesState copyWith({
    ResumoFornecedor? fornecedor,
    bool? carregando,
    String? Function()? erro,
    String? Function()? aviso,
  }) {
    return FornecedoresDetalhesState(
      fornecedor: fornecedor ?? this.fornecedor,
      carregando: carregando ?? this.carregando,
      erro: erro != null ? erro() : this.erro,
      aviso: aviso != null ? aviso() : this.aviso,
    );
  }
}
