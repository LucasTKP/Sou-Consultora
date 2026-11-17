// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Botão quadrado com ícone (ex.: atalho ">" ao lado de uma seleção).
class BotaoIconeApp extends StatelessWidget {
  const BotaoIconeApp({
    super.key,
    required this.dica,
    this.onPressed,
    this.icone = Icons.chevron_right_rounded,
    this.tamanho = 56,
  });

  /// Texto de acessibilidade e tooltip.
  final String dica;
  final VoidCallback? onPressed;
  final IconData icone;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: tamanho,
      child: Tooltip(
        message: dica,
        child: Material(
          color: CoresApp.primariaSuave,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: CoresApp.contorno),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Icon(
              icone,
              color: CoresApp.primariaEscura,
              size: 28,
              semanticLabel: dica,
            ),
          ),
        ),
      ),
    );
  }
}
