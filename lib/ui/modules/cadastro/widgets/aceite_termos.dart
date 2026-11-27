// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Caixa de aceite dos termos, com o botão de leitura e o erro embaixo.
class AceiteTermos extends StatelessWidget {
  const AceiteTermos({
    super.key,
    required this.aceito,
    required this.onAlterar,
    required this.onLer,
    this.erro,
  });

  final bool aceito;

  /// Nulo enquanto grava: a caixa fica travada.
  final ValueChanged<bool>? onAlterar;
  final VoidCallback onLer;
  final String? erro;

  void _alterar(bool? marcado) => onAlterar?.call(marcado ?? false);

  @override
  Widget build(BuildContext context) {
    final mensagem = erro;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: aceito,
          onChanged: onAlterar == null ? null : _alterar,
          isError: mensagem != null,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text(
            'Li e aceito os Termos de Uso e a Política de Privacidade',
          ),
        ),
        if (mensagem != null)
          Text(
            mensagem,
            style: const TextStyle(color: CoresApp.perigo, fontSize: 13),
          ),
        TextButton.icon(
          onPressed: onLer,
          icon: const Icon(Icons.description_outlined),
          label: const Text('Termos de Uso'),
        ),
      ],
    );
  }
}
