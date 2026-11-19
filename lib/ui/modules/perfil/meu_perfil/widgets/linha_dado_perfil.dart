// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Linha de "Meus dados": ícone colorido, rótulo, valor e ação opcional.
class LinhaDadoPerfil extends StatelessWidget {
  const LinhaDadoPerfil({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.valor,
    this.corIcone = CoresApp.primaria,
    this.corFundoIcone = CoresApp.primariaSuave,
    this.complemento,
    this.acao,
  });

  final IconData icone;
  final String rotulo;
  final String valor;
  final Color corIcone;
  final Color corFundoIcone;

  /// Abaixo do valor (ex.: selo "Tipo: Telefone").
  final Widget? complemento;

  /// À direita (ex.: botão copiar).
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: corFundoIcone,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icone, color: corIcone, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo.toUpperCase(),
                  style: estilos.labelSmall?.copyWith(letterSpacing: 0.8),
                ),
                const SizedBox(height: 2),
                Text(valor, style: estilos.titleMedium),
                if (complemento != null) ...[
                  const SizedBox(height: 6),
                  complemento!,
                ],
              ],
            ),
          ),
          ?acao,
        ],
      ),
    );
  }
}
