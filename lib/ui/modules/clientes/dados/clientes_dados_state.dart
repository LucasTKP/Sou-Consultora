import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

class ClientesDadosState {
  const ClientesDadosState({
    this.cliente,
    this.carregando = true,
    this.erro,
    this.aviso,
  });

  final Cliente? cliente;
  final bool carregando;
  final String? erro;

  /// Mensagem passageira (ex.: WhatsApp não abriu). Exibida uma vez.
  final AvisoToast? aviso;

  ClientesDadosState copyWith({
    Cliente? cliente,
    bool? carregando,
    String? Function()? erro,
    AvisoToast? Function()? aviso,
  }) {
    return ClientesDadosState(
      cliente: cliente ?? this.cliente,
      carregando: carregando ?? this.carregando,
      erro: erro != null ? erro() : this.erro,
      aviso: aviso != null ? aviso() : this.aviso,
    );
  }
}
