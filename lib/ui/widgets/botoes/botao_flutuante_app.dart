// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Botão flutuante estendido das listas ("+ Novo cliente").
class BotaoFlutuanteApp extends StatelessWidget {
  const BotaoFlutuanteApp({
    super.key,
    required this.rotulo,
    required this.onPressed,
    this.icone = Icons.add_rounded,
    this.secundario = false,
  });

  final String rotulo;
  final VoidCallback onPressed;
  final IconData icone;

  /// Fundo branco com texto na cor primária (ação de apoio, acima da principal).
  final bool secundario;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: rotulo,
      tooltip: rotulo,
      onPressed: onPressed,
      backgroundColor: secundario ? CoresApp.superficie : CoresApp.primaria,
      foregroundColor: secundario ? CoresApp.primaria : CoresApp.sobrePrimaria,
      shape: StadiumBorder(
        side: secundario
            ? const BorderSide(color: CoresApp.primariaSuave)
            : BorderSide.none,
      ),
      icon: Icon(icone, size: 24),
      label: Text(
        rotulo,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      ),
    );
  }
}
