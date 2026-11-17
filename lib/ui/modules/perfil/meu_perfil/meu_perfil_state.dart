import 'package:sou_consultora/core/model/consultora.dart';

class MeuPerfilState {
  const MeuPerfilState({this.consultora, this.saindo = false});

  final Consultora? consultora;
  final bool saindo;
}
