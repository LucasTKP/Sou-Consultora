// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Interruptor liga/desliga com rótulo e descrição (ex.: "Em espera").
/// Toda a linha é tocável.
class InterruptorApp extends StatelessWidget {
  const InterruptorApp({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.onChanged,
    this.descricao,
  });

  final String rotulo;
  final String? descricao;
  final bool valor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CoresApp.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: CoresApp.primariaSuave),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(!valor),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(child: _textos()),
              Switch(
                value: valor,
                onChanged: onChanged,
                activeThumbColor: CoresApp.sobrePrimaria,
                activeTrackColor: CoresApp.primaria,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CoresApp.sobreSuperficie,
          ),
        ),
        if (descricao != null)
          Text(
            descricao!,
            style: const TextStyle(
              fontSize: 14,
              color: CoresApp.sobreSuperficieVariante,
            ),
          ),
      ],
    );
  }
}
