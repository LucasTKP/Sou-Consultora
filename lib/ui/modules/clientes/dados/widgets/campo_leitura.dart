// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Valor só para leitura, com o rótulo na borda (mesmo visual dos campos do formulário).
class CampoLeitura extends StatelessWidget {
  const CampoLeitura({
    super.key,
    required this.rotulo,
    required this.valor,
    this.icone,
  });

  final String rotulo;
  final String valor;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: rotulo,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: icone == null
            ? null
            : Icon(icone, color: CoresApp.sobreSuperficieVariante),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      child: Text(valor, style: estilos.titleMedium),
    );
  }
}
