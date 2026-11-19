// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Uma opção do [AlternadorSegmentadoApp].
class OpcaoSegmento<T> {
  const OpcaoSegmento({required this.valor, required this.rotulo, this.icone});

  final T valor;
  final String rotulo;
  final IconData? icone;
}

/// Alternador em segmentos (Produto | Serviço, Entradas | Saídas).
class AlternadorSegmentadoApp<T> extends StatelessWidget {
  const AlternadorSegmentadoApp({
    super.key,
    required this.opcoes,
    required this.selecionado,
    required this.onChanged,
  });

  final List<OpcaoSegmento<T>> opcoes;
  final T selecionado;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: CoresApp.primariaSuave.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoresApp.primariaSuave),
      ),
      child: Row(
        children: [
          for (final opcao in opcoes)
            Expanded(child: _segmento(context, opcao)),
        ],
      ),
    );
  }

  Widget _segmento(BuildContext context, OpcaoSegmento<T> opcao) {
    final ativo = opcao.valor == selecionado;
    final cor = ativo ? CoresApp.sobrePrimaria : CoresApp.sobreSuperficie;
    return Semantics(
      selected: ativo,
      button: true,
      child: Material(
        color: ativo ? CoresApp.primaria : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(opcao.valor),
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (opcao.icone != null) ...[
                  Icon(opcao.icone, color: cor, size: 24),
                  const SizedBox(width: 8),
                ],
                // Em tela estreita (ou fonte grande), corta com reticências.
                Flexible(
                  child: Text(
                    opcao.rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
