import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Status visual dos badges do design system.
enum StatusSelo { sucesso, alerta, perigo, neutro, primario }

/// Cor do texto de cada status (selo e linha de situação dos cards).
extension CorDoStatusSelo on StatusSelo {
  Color get corTexto => switch (this) {
    StatusSelo.sucesso => CoresApp.sucesso,
    StatusSelo.alerta => CoresApp.alerta,
    StatusSelo.perigo => CoresApp.perigo,
    StatusSelo.neutro => CoresApp.neutro,
    StatusSelo.primario => CoresApp.primariaEscura,
  };
}

/// Tamanho do selo: [cartao] nas listas e cartões; [pagina] nas telas de detalhe.
enum TamanhoSelo {
  cartao(fonte: 14, horizontal: 12, vertical: 4),
  pagina(fonte: 17, horizontal: 16, vertical: 7);

  const TamanhoSelo({
    required this.fonte,
    required this.horizontal,
    required this.vertical,
  });

  final double fonte;
  final double horizontal;
  final double vertical;
}

/// Selo/badge de status (wrapper de [ShadBadge] com cores do DS).
class SeloStatusApp extends StatelessWidget {
  const SeloStatusApp({
    super.key,
    required this.rotulo,
    this.status = StatusSelo.primario,
    this.tamanho = TamanhoSelo.cartao,
  });

  final String rotulo;
  final StatusSelo status;
  final TamanhoSelo tamanho;

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
      padding: EdgeInsets.symmetric(
        horizontal: tamanho.horizontal,
        vertical: tamanho.vertical,
      ),
      child: Text(
        rotulo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: tamanho.fonte, fontWeight: FontWeight.w600),
      ),
    );
  }
}
