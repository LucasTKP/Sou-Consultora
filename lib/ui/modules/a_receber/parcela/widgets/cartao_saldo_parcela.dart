// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/vendas/widgets/selos_venda.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';

/// Topo dos detalhes: saldo em aberto, barra pago × resta, valor e vencimento.
class CartaoSaldoParcela extends StatelessWidget {
  const CartaoSaldoParcela({
    super.key,
    required this.parcela,
    required this.hoje,
  });

  final ResumoParcela parcela;
  final DateTime hoje;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final status = parcela.status(hoje: hoje);
    return CartaoApp(
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcela.paga ? 'PARCELA QUITADA' : 'SALDO EM ABERTO',
                      style: estilos.labelLarge?.copyWith(
                        color: CoresApp.sobreSuperficieVariante,
                      ),
                    ),
                    Text(
                      FormatadorMoeda.formatar(
                        parcela.paga ? parcela.valor : parcela.saldo,
                      ),
                      style: estilos.displaySmall,
                    ),
                  ],
                ),
              ),
              SeloStatusParcela(tamanho: TamanhoSelo.pagina, status: status),
            ],
          ),
          const SizedBox(height: 16),
          _BarraPagamento(parcela: parcela, atrasada: _atrasada(status)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Quadro(
                  icone: Icons.payments_outlined,
                  rotulo: 'Valor da parcela',
                  valor: FormatadorMoeda.formatar(parcela.valor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _vencimento()),
            ],
          ),
        ],
      ),
    );
  }

  static bool _atrasada(StatusParcela s) => s == StatusParcela.atrasada;

  Widget _vencimento() {
    final data = FormatadorData.curta(parcela.vencimento);
    if (parcela.paga) {
      return _Quadro(
        icone: Icons.event_available_outlined,
        rotulo: 'Vencimento',
        valor: data,
      );
    }
    if (parcela.venceHoje(hoje: hoje)) {
      return _Quadro(
        icone: Icons.event_outlined,
        rotulo: 'Vence hoje',
        valor: data,
        cor: CoresApp.alerta,
      );
    }
    final dias = parcela.diasAtraso(hoje: hoje);
    if (dias > 0) {
      return _Quadro(
        icone: Icons.event_busy_outlined,
        rotulo: 'Venceu em $data',
        valor: dias == 1 ? 'há 1 dia' : 'há $dias dias',
        cor: CoresApp.perigo,
      );
    }
    return _Quadro(
      icone: Icons.event_outlined,
      rotulo: 'Vence em',
      valor: data,
    );
  }
}

class _BarraPagamento extends StatelessWidget {
  const _BarraPagamento({required this.parcela, required this.atrasada});

  final ResumoParcela parcela;
  final bool atrasada;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.titleSmall;
    final corResta = atrasada ? CoresApp.perigo : CoresApp.alerta;
    final fracao = parcela.valor == 0 ? 1.0 : parcela.valorPago / parcela.valor;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fracao.clamp(0, 1).toDouble(),
            minHeight: 10,
            color: CoresApp.sucesso,
            backgroundColor: corResta,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Pago ${FormatadorMoeda.formatar(parcela.valorPago)}',
                style: estilo?.copyWith(color: CoresApp.sucesso),
              ),
            ),
            Text(
              'Resta ${FormatadorMoeda.formatar(parcela.saldo)}',
              style: estilo?.copyWith(color: corResta),
            ),
          ],
        ),
      ],
    );
  }
}

class _Quadro extends StatelessWidget {
  const _Quadro({
    required this.icone,
    required this.rotulo,
    required this.valor,
    this.cor,
  });

  final IconData icone;
  final String rotulo;
  final String valor;

  /// Cor de destaque (null = neutro).
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final destaque = cor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: destaque == null
            ? CoresApp.primariaSuave.withOpacity(0.35)
            : destaque.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: destaque?.withOpacity(0.35) ?? CoresApp.contorno,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icone,
                size: 24,
                color: destaque ?? CoresApp.sobreSuperficieVariante,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rotulo,
                  style: estilos.bodySmall?.copyWith(color: destaque),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(valor, style: estilos.titleMedium?.copyWith(color: destaque)),
        ],
      ),
    );
  }
}
