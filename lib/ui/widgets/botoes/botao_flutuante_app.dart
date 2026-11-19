// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Botão flutuante estendido das listas ("+ Novo cliente").
class BotaoFlutuanteApp extends StatelessWidget {
  const BotaoFlutuanteApp({
    super.key,
    required this.rotulo,
    required this.onPressed,
    this.icone = Icons.add_rounded,
    this.secundario = false,
    this.destaque = false,
  });

  final String rotulo;
  final VoidCallback onPressed;
  final IconData icone;

  /// Fundo branco com texto na cor primária (ação de apoio, acima da principal).
  final bool secundario;

  /// Ação principal da tela: botão maior, com um "fundinho" (halo claro e
  /// sombra na cor da marca) que o separa da lista.
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final botao = _botao();
    if (!destaque) return botao;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CoresApp.primariaSuave,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: CoresApp.primaria.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(6), child: botao),
    );
  }

  Widget _botao() {
    return FloatingActionButton.extended(
      heroTag: rotulo,
      tooltip: rotulo,
      onPressed: onPressed,
      backgroundColor: secundario ? CoresApp.superficie : CoresApp.primaria,
      foregroundColor: secundario ? CoresApp.primaria : CoresApp.sobrePrimaria,
      shape: StadiumBorder(
        side: secundario
            ? const BorderSide(color: CoresApp.primariaSuave)
            : BorderSide.none,
      ),
      elevation: destaque ? 6 : null,
      extendedPadding: destaque
          ? const EdgeInsetsDirectional.symmetric(horizontal: 24)
          : null,
      icon: Icon(icone, size: destaque ? 28 : 24),
      label: Text(
        rotulo,
        style: TextStyle(
          fontSize: destaque ? 19 : 17,
          fontWeight: destaque ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
