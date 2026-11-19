// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Linha "rótulo ............ valor" dos detalhes do produto.
/// [emBloco] põe o valor embaixo do rótulo (textos longos, como observações).
class LinhaInformacao extends StatelessWidget {
  const LinhaInformacao({
    super.key,
    required this.rotulo,
    required this.valor,
    this.dica,
    this.destaque = false,
    this.emBloco = false,
  });

  final String rotulo;
  final String valor;

  /// Texto pequeno abaixo do rótulo (ex.: "Ideal para prever recompra").
  final String? dica;
  final bool destaque;
  final bool emBloco;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final estiloRotulo = estilos.bodyLarge?.copyWith(
      color: CoresApp.sobreSuperficieVariante,
    );
    final estiloValor = estilos.titleSmall?.copyWith(
      color: destaque ? CoresApp.primaria : null,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CoresApp.primariaSuave)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: emBloco
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rotulo, style: estiloRotulo),
                  const SizedBox(height: 8),
                  Text(valor, style: estilos.bodyLarge),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _rotulo(estiloRotulo, estilos)),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      valor,
                      textAlign: TextAlign.end,
                      style: estiloValor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _rotulo(TextStyle? estilo, TextTheme estilos) {
    final texto = dica;
    if (texto == null) return Text(rotulo, style: estilo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: estilo),
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              size: 24,
              color: CoresApp.primaria,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                texto,
                style: estilos.labelMedium?.copyWith(color: CoresApp.primaria),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
