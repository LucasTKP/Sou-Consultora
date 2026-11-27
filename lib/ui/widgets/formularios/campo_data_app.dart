// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';

/// Campo de data: toque abre o calendário em pt-BR e mostra dd/MM/aaaa.
class CampoDataApp extends StatefulWidget {
  const CampoDataApp({
    super.key,
    required this.rotulo,
    required this.onChanged,
    this.data,
    this.primeiraData,
    this.ultimaData,
    this.obrigatorio = false,
    this.opcional = false,
    this.erro,
  });

  final String rotulo;
  final ValueChanged<DateTime> onChanged;
  final DateTime? data;
  final DateTime? primeiraData;
  final DateTime? ultimaData;
  final bool obrigatorio;
  final bool opcional;
  final String? erro;

  @override
  State<CampoDataApp> createState() => _CampoDataAppState();
}

class _CampoDataAppState extends State<CampoDataApp> {
  late final TextEditingController _controle = TextEditingController(
    text: _texto(widget.data),
  );

  @override
  void didUpdateWidget(CampoDataApp antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.data != widget.data) _controle.text = _texto(widget.data);
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  String _texto(DateTime? data) =>
      data == null ? '' : FormatadorData.curta(data);

  Future<void> _abrirCalendario() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: widget.data ?? hoje,
      firstDate: widget.primeiraData ?? DateTime(hoje.year - 10),
      lastDate: widget.ultimaData ?? DateTime(hoje.year + 10),
    );
    if (escolhida != null) widget.onChanged(escolhida);
  }

  @override
  Widget build(BuildContext context) {
    return CampoTextoApp(
      rotulo: widget.rotulo,
      obrigatorio: widget.obrigatorio,
      opcional: widget.opcional,
      erro: widget.erro,
      somenteLeitura: true,
      placeholder: 'DD/MM/AAAA',
      controller: _controle,
      onTap: _abrirCalendario,
      leading: const Icon(
        Icons.calendar_today_outlined,
        color: CoresApp.primaria,
      ),
    );
  }
}
