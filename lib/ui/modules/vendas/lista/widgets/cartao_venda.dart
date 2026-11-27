// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/core/model/venda.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/vendas/widgets/selos_venda.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_app.dart';

/// Card da venda: iniciais, cliente, quando, itens, total e status.
class CartaoVenda extends StatelessWidget {
  const CartaoVenda({
    super.key,
    required this.venda,
    required this.hoje,
    required this.onTap,
  });

  final ResumoVenda venda;
  final DateTime hoje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final variante = estilos.bodySmall?.copyWith(
      color: CoresApp.sobreSuperficieVariante,
    );
    return Semantics(
      button: true,
      label: 'Venda ${venda.codigoTexto} de ${venda.clienteNome}',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: CartaoApp(
          filho: Column(
            children: [
              Row(
                children: [
                  AvatarApp(iniciais: Cliente.iniciaisDe(venda.clienteNome)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venda.clienteNome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: estilos.titleMedium,
                        ),
                        Text(
                          '${FormatadorData.quando(venda.dataVenda, hoje: hoje)}'
                          '  ${venda.codigoTexto}',
                          style: variante,
                        ),
                      ],
                    ),
                  ),
                  SeloStatusVenda(status: venda.status),
                ],
              ),
              const Divider(height: 24, color: CoresApp.primariaSuave),
              Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 24,
                    color: CoresApp.sobreSuperficieVariante,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(venda.textoItens, style: variante)),
                  Text(
                    FormatadorMoeda.formatar(venda.total),
                    style: estilos.titleMedium?.copyWith(
                      color: CoresApp.primaria,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: CoresApp.primaria,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
