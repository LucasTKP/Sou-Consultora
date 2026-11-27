// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/formatadores/formatador_percentual.dart';
import 'package:sou_consultora/ui/formatadores/mascaras.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';

/// Campo de porcentagem. Trabalha com **centésimos inteiros** (1250 = 12,5%).
class CampoPercentualApp extends StatefulWidget {
  const CampoPercentualApp({
    super.key,
    required this.rotulo,
    required this.onChanged,
    this.centesimosIniciais = 0,
    this.opcional = false,
    this.erro,
  });

  final String rotulo;
  final ValueChanged<int> onChanged;
  final int centesimosIniciais;
  final bool opcional;
  final String? erro;

  @override
  State<CampoPercentualApp> createState() => _CampoPercentualAppState();
}

class _CampoPercentualAppState extends State<CampoPercentualApp> {
  late final TextEditingController _controle = TextEditingController(
    text: FormatadorPercentual.formatar(widget.centesimosIniciais),
  );

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  void _aoMudar(String texto) =>
      widget.onChanged(FormatadorPercentual.ler(texto));

  @override
  Widget build(BuildContext context) {
    return CampoTextoApp(
      rotulo: widget.rotulo,
      opcional: widget.opcional,
      erro: widget.erro,
      controller: _controle,
      placeholder: '0',
      teclado: const TextInputType.numberWithOptions(decimal: true),
      formatadores: [MascaraPercentual()],
      onChanged: _aoMudar,
      leading: const Icon(Icons.percent_rounded),
    );
  }
}
