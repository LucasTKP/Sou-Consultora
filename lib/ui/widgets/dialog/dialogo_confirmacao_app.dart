// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';

/// Diálogo de confirmação. Devolve `true` ao confirmar e `false` ao cancelar ou fechar.
///
/// Fundo branco, faixa rosa no topo, X para fechar e os botões na mesma linha:
/// cancelar no canto esquerdo e confirmar no direito.
abstract final class DialogoConfirmacaoApp {
  static Future<bool> mostrar({
    required BuildContext context,
    required String titulo,
    required String mensagem,
    required String rotuloConfirmar,
    String rotuloCancelar = 'Cancelar',
    bool perigo = false,
  }) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => _CorpoDialogo(
        titulo: titulo,
        mensagem: mensagem,
        rotuloConfirmar: rotuloConfirmar,
        rotuloCancelar: rotuloCancelar,
        perigo: perigo,
      ),
    );
    return confirmou ?? false;
  }
}

class _CorpoDialogo extends StatelessWidget {
  const _CorpoDialogo({
    required this.titulo,
    required this.mensagem,
    required this.rotuloConfirmar,
    required this.rotuloCancelar,
    required this.perigo,
  });

  final String titulo;
  final String mensagem;
  final String rotuloConfirmar;
  final String rotuloCancelar;
  final bool perigo;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    void confirmar() => Navigator.of(context).pop(true);
    void cancelar() => Navigator.of(context).pop(false);

    return Dialog(
      backgroundColor: CoresApp.superficie,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: CoresApp.primaria,
              padding: const EdgeInsets.fromLTRB(24, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      style: estilos.titleLarge?.copyWith(
                        color: CoresApp.sobrePrimaria,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: cancelar,
                    color: CoresApp.sobrePrimaria,
                    icon: const Icon(Icons.close_rounded, size: 24),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Text(mensagem, style: estilos.bodyLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: BotaoApp.contorno(
                      rotulo: rotuloCancelar,
                      onPressed: cancelar,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: perigo
                        ? BotaoApp.perigo(
                            rotulo: rotuloConfirmar,
                            onPressed: confirmar,
                          )
                        : BotaoApp(
                            rotulo: rotuloConfirmar,
                            onPressed: confirmar,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
