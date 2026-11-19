import 'package:sou_consultora/core/model/detalhe_venda.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

enum AbaVenda { itens, pagamento }

class VendasDetalhesState {
  const VendasDetalhesState({
    required this.hoje,
    this.detalhe,
    this.carregando = true,
    this.erro,
    this.aba = AbaVenda.itens,
    this.processando = false,
    this.cancelada = false,
    this.aviso,
  });

  final DateTime hoje;
  final DetalheVenda? detalhe;
  final bool carregando;
  final String? erro;
  final AbaVenda aba;

  /// Cancelando a venda.
  final bool processando;

  /// A venda foi cancelada: a tela fecha.
  final bool cancelada;
  final AvisoToast? aviso;

  VendasDetalhesState copyWith({
    DetalheVenda? detalhe,
    bool? carregando,
    String? Function()? erro,
    AbaVenda? aba,
    bool? processando,
    bool? cancelada,
    AvisoToast? Function()? aviso,
  }) {
    return VendasDetalhesState(
      hoje: hoje,
      detalhe: detalhe ?? this.detalhe,
      carregando: carregando ?? this.carregando,
      erro: erro != null ? erro() : this.erro,
      aba: aba ?? this.aba,
      processando: processando ?? this.processando,
      cancelada: cancelada ?? this.cancelada,
      aviso: aviso != null ? aviso() : this.aviso,
    );
  }
}
