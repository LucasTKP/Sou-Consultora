// ignore_for_file: deprecated_member_use
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:flutter/material.dart';

class CabecalhoMarcaLogin extends StatelessWidget {
  const CabecalhoMarcaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    final tipografia = Theme.of(context).textTheme;

    return Column(
      children: [
        Image.asset(
          'assets/imagens/logo.png',
          width: 128,
          height: 128,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 22),
        Text(
          'O app da consultora de beleza independente',
          textAlign: TextAlign.center,
          style: tipografia.bodyLarge?.copyWith(
            color: CoresApp.primaria,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
