import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Status visual dos badges do design system.
enum StatusSelo { sucesso, alerta, perigo, neutro, primario }

/// Selo/badge de status (wrapper de [ShadBadge] com cores do DS).
class SeloStatusApp extends StatelessWidget {
  const SeloStatusApp({
    super.key,
    required this.rotulo,
    this.status = StatusSelo.primario,
  });

  final String rotulo;
  final StatusSelo status;

  @override
  Widget build(BuildContext context) {
    final (fundo, texto) = switch (status) {
      StatusSelo.sucesso => (CoresApp.sucessoContainer, CoresApp.sucesso),
      StatusSelo.alerta => (CoresApp.alertaContainer, CoresApp.alerta),
      StatusSelo.perigo => (CoresApp.perigoContainer, CoresApp.perigo),
      StatusSelo.neutro => (CoresApp.neutroContainer, CoresApp.neutro),
      StatusSelo.primario => (CoresApp.primariaSuave, CoresApp.primariaEscura),
    };

    return ShadBadge(
      backgroundColor: fundo,
      foregroundColor: texto,
      hoverBackgroundColor: fundo,
      child: Text(rotulo, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
