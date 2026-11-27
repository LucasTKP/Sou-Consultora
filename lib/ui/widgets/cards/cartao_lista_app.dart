// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Linha em card das listas: avatar/foto, título, subtítulo, selo e seta.
class CartaoListaApp extends StatelessWidget {
  const CartaoListaApp({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.inicio,
    this.maxLinhasTitulo = 1,
    this.linhaInferior,
    this.selo,
    this.fim,
    this.onTap,
    this.mostrarSeta = true,
  });

  final String titulo;
  final String? subtitulo;

  /// Quantas linhas o título pode usar antes das reticências (nomes longos).
  final int maxLinhasTitulo;

  /// Widget no lugar do [subtitulo] (ex.: valor e status lado a lado).
  final Widget? linhaInferior;

  /// Normalmente `AvatarApp` ou `FotoQuadradaApp`.
  final Widget? inicio;

  /// Normalmente `SeloStatusApp`.
  final Widget? selo;

  /// Conteúdo à direita no lugar do selo (ex.: valor).
  final Widget? fim;
  final VoidCallback? onTap;
  final bool mostrarSeta;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final larguraMaximaSelo = MediaQuery.sizeOf(context).width * 0.45;
    return Material(
      color: CoresApp.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: CoresApp.primariaSuave),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (inicio != null) ...[inicio!, const SizedBox(width: 16)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: maxLinhasTitulo,
                      overflow: TextOverflow.ellipsis,
                      style: estilos.titleMedium,
                    ),
                    if (linhaInferior != null)
                      linhaInferior!
                    else if (subtitulo != null)
                      Text(
                        subtitulo!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: estilos.bodySmall,
                      ),
                  ],
                ),
              ),
              // Com fonte grande, o selo ocupa no máximo 45% da linha (reticências) em vez de estourar.
              if (selo != null) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: larguraMaximaSelo),
                  child: selo!,
                ),
              ],
              if (fim != null) ...[const SizedBox(width: 8), fim!],
              if (mostrarSeta && onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: CoresApp.sobreSuperficieVariante,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
