// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sou_consultora/core/model/dica_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Um passo do passo a passo: destaca o [child] com um balão de título e texto.
///
/// Só aparece quando o [RoteiroDicas] da mesma [dica] é iniciado com a [chave]
/// deste passo; fora disso é transparente e não muda nada na tela.
class PassoDeDica extends StatelessWidget {
  const PassoDeDica({
    super.key,
    required this.chave,
    required this.dica,
    required this.titulo,
    required this.descricao,
    required this.child,
    this.raio = 16,
  });

  /// Identifica o elemento destacado (a mesma chave vai para o roteiro).
  final GlobalKey chave;
  final DicaApp dica;
  final String titulo;
  final String descricao;
  final Widget child;

  /// Arredondamento do recorte em volta do elemento.
  final double raio;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Showcase(
      key: chave,
      scope: dica.chave,
      title: titulo,
      description: descricao,
      titleTextAlign: TextAlign.center,
      descriptionTextAlign: TextAlign.center,
      titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      descriptionPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      titleTextStyle: estilos.titleMedium?.copyWith(
        color: CoresApp.primariaEscura,
        fontWeight: FontWeight.w700,
      ),
      descTextStyle: estilos.bodyMedium?.copyWith(
        color: CoresApp.sobreSuperficie,
      ),
      tooltipBackgroundColor: CoresApp.superficie,
      overlayColor: CoresApp.sobreSuperficie,
      overlayOpacity: 0.7,
      targetBorderRadius: BorderRadius.circular(raio),
      targetPadding: const EdgeInsets.all(4),
      child: child,
    );
  }
}
