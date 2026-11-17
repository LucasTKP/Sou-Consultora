// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';

/// Área de texto (observações) com o mesmo visual do [CampoTextoApp].
class AreaTextoApp extends StatelessWidget {
  const AreaTextoApp({
    super.key,
    this.rotulo,
    this.opcional = false,
    this.controller,
    this.placeholder,
    this.habilitado = true,
    this.onChanged,
    this.linhas = 3,
    this.erro,
  });

  final String? rotulo;
  final bool opcional;
  final TextEditingController? controller;
  final String? placeholder;
  final bool habilitado;
  final ValueChanged<String>? onChanged;
  final int linhas;
  final String? erro;

  @override
  Widget build(BuildContext context) {
    return CampoTextoApp(
      rotulo: rotulo,
      opcional: opcional,
      controller: controller,
      placeholder: placeholder,
      habilitado: habilitado,
      onChanged: onChanged,
      linhas: linhas,
      erro: erro,
      capitalizacao: TextCapitalization.sentences,
    );
  }
}
