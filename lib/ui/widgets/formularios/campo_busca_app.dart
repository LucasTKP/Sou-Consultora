// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';

/// Campo de busca das listas ("Buscar por nome, marca ou código...").
class CampoBuscaApp extends StatelessWidget {
  const CampoBuscaApp({
    super.key,
    required this.placeholder,
    this.rotulo,
    this.controller,
    this.onChanged,
  });

  final String placeholder;
  final String? rotulo;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return CampoTextoApp(
      rotulo: rotulo,
      placeholder: placeholder,
      controller: controller,
      onChanged: onChanged,
      acaoTeclado: TextInputAction.search,
      leading: const Icon(Icons.search_rounded, color: CoresApp.primaria),
    );
  }
}
