// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/formatadores/mascaras.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';

/// Campo de valor em R$. Trabalha sempre com **centavos inteiros**.
class CampoMoedaApp extends StatefulWidget {
  const CampoMoedaApp({
    super.key,
    required this.rotulo,
    required this.onChanged,
    this.centavosIniciais = 0,
    this.obrigatorio = false,
    this.opcional = false,
    this.erro,
    this.habilitado = true,
  });

  final String rotulo;
  final ValueChanged<int> onChanged;
  final int centavosIniciais;
  final bool obrigatorio;
  final bool opcional;
  final String? erro;
  final bool habilitado;

  @override
  State<CampoMoedaApp> createState() => _CampoMoedaAppState();
}

class _CampoMoedaAppState extends State<CampoMoedaApp> {
  late final TextEditingController _controle = TextEditingController(
    text: FormatadorMoeda.formatarSemSimbolo(widget.centavosIniciais),
  );

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  void _aoMudar(String texto) => widget.onChanged(FormatadorMoeda.ler(texto));

  @override
  Widget build(BuildContext context) {
    return CampoTextoApp(
      rotulo: widget.rotulo,
      obrigatorio: widget.obrigatorio,
      opcional: widget.opcional,
      erro: widget.erro,
      habilitado: widget.habilitado,
      controller: _controle,
      teclado: TextInputType.number,
      formatadores: [MascaraMoeda()],
      onChanged: _aoMudar,
      leading: const Padding(
        padding: EdgeInsets.only(left: 16, right: 8),
        child: Text(
          r'R$',
          style: TextStyle(
            fontSize: 17,
            color: CoresApp.sobreSuperficieVariante,
          ),
        ),
      ),
    );
  }
}
