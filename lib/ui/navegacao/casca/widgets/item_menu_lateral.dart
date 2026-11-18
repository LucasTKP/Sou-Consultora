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
    this.selo,
  });

  final String rotulo;
  final IconData icone;
  final VoidCallback onTap;
  final bool atual;

  /// Cor especial (ex.: vermelho de "Sair da conta").
  final Color? cor;

  /// Número em destaque à direita (ex.: cobranças atrasadas); null = sem selo.
  final int? selo;

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
                if (selo case final quantidade?)
                  Semantics(
                    label: '$quantidade atrasadas',
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CoresApp.perigo,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        quantidade > 99 ? '99+' : '$quantidade',
                        style: const TextStyle(
                          color: CoresApp.sobrePrimaria,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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
