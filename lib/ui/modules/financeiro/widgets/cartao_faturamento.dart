// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/resumo_financeiro.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/graficos/grafico_barras_app.dart';

/// "Faturamento - Últimos 12 meses": total acumulado e o gráfico, com o mês
/// do período em destaque.
class CartaoFaturamento extends StatelessWidget {
  const CartaoFaturamento({super.key, required this.resumo});

  final ResumoFinanceiro resumo;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final meses = resumo.meses;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CoresApp.contorno),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 8, color: CoresApp.primaria),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Faturamento - Últimos 12 meses',
                  style: estilos.titleSmall?.copyWith(
                    color: CoresApp.sobreSuperficieVariante,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  children: [
                    Text(
                      FormatadorMoeda.formatarSemCentavos(
                        resumo.totalAcumulado,
                      ),
                      style: estilos.displaySmall?.copyWith(
                        color: CoresApp.primaria,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'total acumulado',
                        style: estilos.titleSmall?.copyWith(
                          color: CoresApp.sobreSuperficieVariante,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28, color: CoresApp.contorno),
                GraficoBarrasApp(
                  destaque: meses.length - 1,
                  rotuloDestaque: FormatadorMoeda.abreviado(meses.last.valor),
                  barras: [
                    for (final mes in meses)
                      BarraGrafico(
                        rotulo: FormatadorData.mesCurto(mes.mes.mes),
                        valor: mes.valor,
                        descricao:
                            '${FormatadorData.mesAnoPorExtenso(mes.mes.ano, mes.mes.mes)}: '
                            '${FormatadorMoeda.formatar(mes.valor)}',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
