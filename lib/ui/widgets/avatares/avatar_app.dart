import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Tamanhos de avatar do design system (1:1, object-cover).
enum TamanhoAvatar {
  destaque(80),
  card(56),
  miniatura(40);

  const TamanhoAvatar(this.lado);
  final double lado;
}

/// Avatar do app (wrapper de [ShadAvatar]) — foto ou iniciais.
class AvatarApp extends StatelessWidget {
  const AvatarApp({
    super.key,
    this.urlImagem,
    this.iniciais,
    this.tamanho = TamanhoAvatar.card,
    this.corFundo,
  });

  /// URL/asset da foto. Se nulo, mostra [iniciais].
  final String? urlImagem;
  final String? iniciais;
  final TamanhoAvatar tamanho;
  final Color? corFundo;

  @override
  Widget build(BuildContext context) {
    final lado = tamanho.lado;
    final texto = (iniciais ?? '?').trim();
    final placeholder = Text(
      texto.isEmpty ? '?' : (texto.length <= 2 ? texto : texto.substring(0, 2)),
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: lado * 0.32,
        color: CoresApp.primariaEscura,
      ),
    );

    final semFoto = urlImagem == null || urlImagem!.trim().isEmpty;
    return ShadAvatar(
      // Com src nulo o ShadAvatar mostra o placeholder (iniciais).
      semFoto ? null : urlImagem,
      size: Size.square(lado),
      backgroundColor: corFundo ?? CoresApp.primariaSuave,
      fit: BoxFit.cover,
      placeholder: Center(child: placeholder),
    );
  }
}
