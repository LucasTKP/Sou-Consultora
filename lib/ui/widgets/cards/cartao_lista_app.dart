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
    this.selo,
    this.fim,
    this.onTap,
    this.mostrarSeta = true,
  });

  final String titulo;
  final String? subtitulo;

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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: estilos.titleMedium,
                    ),
                    if (subtitulo != null)
                      Text(
                        subtitulo!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: estilos.bodySmall,
                      ),
                  ],
                ),
              ),
              if (selo != null) ...[const SizedBox(width: 8), selo!],
              if (fim != null) ...[const SizedBox(width: 8), fim!],
              if (mostrarSeta && onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: CoresApp.sobreSuperficieVariante,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
