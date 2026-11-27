// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/lote_produto.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_app.dart';

/// Um lote na aba Estoque: número, data, fornecedor, custo, total, validade e
/// quanto resta. Lote sem vendas mostra a lixeira ([onApagar]).
class CartaoLote extends StatelessWidget {
  const CartaoLote({super.key, required this.lote, this.onApagar});

  final LoteProduto lote;
  final VoidCallback? onApagar;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final rotulo = estilos.bodySmall?.copyWith(
      color: CoresApp.sobreSuperficieVariante,
    );
    final validade = lote.validade;
    return CartaoApp(
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Numero(rotulo: lote.rotulo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lote ${FormatadorData.curta(lote.dataCompra)}',
                      style: estilos.titleMedium,
                    ),
                    Text('Fornecedor: ${lote.fornecedorNome}', style: rotulo),
                  ],
                ),
              ),
              SeloStatusApp(
                rotulo: lote.textoSituacao,
                status: switch (lote.situacao) {
                  SituacaoLote.recebido => StatusSelo.neutro,
                  SituacaoLote.restante => StatusSelo.alerta,
                  SituacaoLote.esgotado => StatusSelo.perigo,
                },
              ),
            ],
          ),
          const Divider(height: 24, color: CoresApp.primariaSuave),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Custo unitário', style: rotulo),
                    Text(
                      FormatadorMoeda.formatar(lote.custoUnitario),
                      style: estilos.titleSmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total pago', style: rotulo),
                  Text(
                    FormatadorMoeda.formatar(lote.totalPago),
                    style: estilos.titleSmall?.copyWith(
                      color: CoresApp.primaria,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (validade != null)
                Expanded(
                  child: Text(
                    'Validade: ${FormatadorData.curta(validade)}',
                    style: estilos.bodyMedium,
                  ),
                )
              else
                const Spacer(),
              Text(
                lote.textoSaldo,
                style: estilos.bodyMedium?.copyWith(
                  color: lote.situacao == SituacaoLote.recebido
                      ? CoresApp.sucesso
                      : CoresApp.sobreSuperficieVariante,
                ),
              ),
              if (onApagar != null)
                IconButton(
                  tooltip: 'Apagar lote ${lote.rotulo}',
                  onPressed: onApagar,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: CoresApp.perigo,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({required this.rotulo});

  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CoresApp.primariaSuave,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        rotulo,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: CoresApp.primariaEscura),
      ),
    );
  }
}
