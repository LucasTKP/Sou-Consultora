// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// "Categorias do Mês": A Receber (faturamento) e A Pagar (despesas).
class CartaoCategorias extends StatelessWidget {
  const CartaoCategorias({
    super.key,
    required this.faturamento,
    required this.despesas,
    required this.onAReceber,
    required this.onAPagar,
  });

  /// Centavos.
  final int faturamento;
  final int despesas;
  final VoidCallback onAReceber;
  final VoidCallback onAPagar;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CoresApp.contorno),
      ),
      child: Column(
        children: [
          _Linha(
            icone: Icons.payments_outlined,
            fundo: CoresApp.primariaSuave,
            corIcone: CoresApp.primaria,
            titulo: 'A Receber',
            rotulo: 'Faturamento:',
            valor: faturamento,
            corValor: CoresApp.primaria,
            onTap: onAReceber,
          ),
          const Divider(height: 1, color: CoresApp.contorno),
          _Linha(
            icone: Icons.receipt_long_outlined,
            fundo: CoresApp.perigoContainer,
            corIcone: CoresApp.perigo,
            titulo: 'A Pagar',
            rotulo: 'Despesas:',
            valor: despesas,
            corValor: CoresApp.perigo,
            onTap: onAPagar,
          ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.icone,
    required this.fundo,
    required this.corIcone,
    required this.titulo,
    required this.rotulo,
    required this.valor,
    required this.corValor,
    required this.onTap,
  });

  final IconData icone;
  final Color fundo;
  final Color corIcone;
  final String titulo;
  final String rotulo;
  final int valor;
  final Color corValor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$titulo, $rotulo ${FormatadorMoeda.formatar(valor)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: fundo,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icone, color: corIcone, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: estilos.titleLarge),
                    Text.rich(
                      TextSpan(
                        text: '$rotulo ',
                        children: [
                          TextSpan(
                            text: FormatadorMoeda.formatar(valor),
                            style: TextStyle(
                              color: corValor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      style: estilos.bodyMedium?.copyWith(
                        color: CoresApp.sobreSuperficieVariante,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
