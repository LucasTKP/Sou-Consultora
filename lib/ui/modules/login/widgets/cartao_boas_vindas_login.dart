// ignore_for_file: deprecated_member_use
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:flutter/material.dart';

class CartaoBoasVindasLogin extends StatelessWidget {
  const CartaoBoasVindasLogin({super.key});

  @override
  Widget build(BuildContext context) {
    final tipografia = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoresApp.contorno.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: CoresApp.primariaEscura.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Boas-vindas!', style: tipografia.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Acesse suas vendas, clientes e pedidos com facilidade e segurança.',
            style: tipografia.bodyMedium?.copyWith(color: CoresApp.sobreSuperficieVariante, height: 1.4),
          ),
        ],
      ),
    );
  }
}
