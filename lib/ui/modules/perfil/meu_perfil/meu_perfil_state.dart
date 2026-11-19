import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

class MeuPerfilState {
  const MeuPerfilState({this.consultora, this.saindo = false, this.aviso});

  final Consultora? consultora;
  final bool saindo;

  /// Mensagem passageira (ex.: não foi possível abrir o WhatsApp do suporte).
  final AvisoToast? aviso;
}
