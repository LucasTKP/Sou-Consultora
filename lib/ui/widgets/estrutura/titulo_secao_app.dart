// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Título de seção com ícone (ex.: "Meus dados", "Recebimento via Pix").
class TituloSecaoApp extends StatelessWidget {
  const TituloSecaoApp({super.key, required this.titulo, required this.icone});

  final String titulo;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.headlineLarge;
    return Row(
      children: [
        Icon(icone, color: CoresApp.primaria, size: 30),
        const SizedBox(width: 12),
        Flexible(child: Text(titulo, style: estilo)),
      ],
    );
  }
}
