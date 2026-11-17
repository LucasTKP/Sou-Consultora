// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Linha do menu lateral. Destacada quando é o módulo atual.
class ItemMenuLateral extends StatelessWidget {
  const ItemMenuLateral({
    super.key,
    required this.rotulo,
    required this.icone,
    required this.onTap,
    this.atual = false,
    this.cor,
  });

  final String rotulo;
  final IconData icone;
  final VoidCallback onTap;
  final bool atual;

  /// Cor especial (ex.: vermelho de "Sair da conta").
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final corConteudo =
        cor ?? (atual ? CoresApp.primariaEscura : CoresApp.sobreSuperficie);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: atual ? const Color(0xFFFCDDE7) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icone,
                  color: atual
                      ? CoresApp.primaria
                      : (cor ?? CoresApp.sobreSuperficieVariante),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    rotulo,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: atual ? FontWeight.w700 : FontWeight.w500,
                      color: corConteudo,
                    ),
                  ),
                ),
                if (atual)
                  const CircleAvatar(
                    radius: 5,
                    backgroundColor: CoresApp.primaria,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
