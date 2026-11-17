// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Barra inferior fixa: Produtos, Clientes, Início (central), Vendas, Financeiro.
class BarraInferior extends StatelessWidget {
  const BarraInferior({
    super.key,
    required this.itemAtivo,
    required this.onSelecionar,
  });

  /// Null quando o módulo aberto não está na barra.
  final ItemBarra? itemAtivo;
  final ValueChanged<ItemBarra> onSelecionar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              _item(ItemBarra.produtos, 'Produtos', Icons.inventory_2_outlined),
              _item(ItemBarra.clientes, 'Clientes', Icons.people_alt_outlined),
              Expanded(
                child: _ItemCentral(
                  ativo: itemAtivo == ItemBarra.inicio,
                  onTap: () => onSelecionar(ItemBarra.inicio),
                ),
              ),
              _item(ItemBarra.vendas, 'Vendas', Icons.receipt_long_outlined),
              _item(
                ItemBarra.financeiro,
                'Financeiro',
                Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(ItemBarra item, String rotulo, IconData icone) {
    return Expanded(
      child: _ItemBarraSimples(
        rotulo: rotulo,
        icone: icone,
        ativo: item == itemAtivo,
        onTap: () => onSelecionar(item),
      ),
    );
  }
}

class _ItemBarraSimples extends StatelessWidget {
  const _ItemBarraSimples({
    required this.rotulo,
    required this.icone,
    required this.ativo,
    required this.onTap,
  });

  final String rotulo;
  final IconData icone;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? CoresApp.primaria : CoresApp.sobreSuperficieVariante;
    return Semantics(
      selected: ativo,
      button: true,
      label: rotulo,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: cor, size: 28),
            const SizedBox(height: 4),
            Text(
              rotulo,
              style: TextStyle(
                color: cor,
                fontSize: 13,
                fontWeight: ativo ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão redondo em destaque do Início, elevado acima da barra.
class _ItemCentral extends StatelessWidget {
  const _ItemCentral({required this.ativo, required this.onTap});

  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: ativo,
      button: true,
      label: 'Início',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: OverflowBox(
          maxHeight: 110,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: CoresApp.primaria,
                  shape: BoxShape.circle,
                  border: Border.all(color: CoresApp.superficie, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33B0396F),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: CoresApp.sobrePrimaria,
                  size: 32,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Início',
                style: TextStyle(
                  color: ativo
                      ? CoresApp.primaria
                      : CoresApp.sobreSuperficieVariante,
                  fontSize: 13,
                  fontWeight: ativo ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
