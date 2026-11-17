// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';

/// Diálogo de confirmação. Devolve `true` ao confirmar e `false` ao cancelar ou fechar.
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
      builder: (contexto) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _botaoConfirmar(contexto, rotuloConfirmar, perigo),
              const SizedBox(height: 8),
              BotaoApp.contorno(
                rotulo: rotuloCancelar,
                onPressed: () => Navigator.of(contexto).pop(false),
              ),
            ],
          ),
        ],
      ),
    );
    return confirmou ?? false;
  }

  static Widget _botaoConfirmar(
    BuildContext contexto,
    String rotulo,
    bool perigo,
  ) {
    void confirmar() => Navigator.of(contexto).pop(true);
    if (perigo) return BotaoApp.perigo(rotulo: rotulo, onPressed: confirmar);
    return BotaoApp(rotulo: rotulo, onPressed: confirmar);
  }
}
