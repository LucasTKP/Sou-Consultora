import 'package:flutter/material.dart';

class CabecalhoMarcaLogin extends StatelessWidget {
  const CabecalhoMarcaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/imagens/logo.png',
      width: 128,
      height: 128,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    );
  }
}
