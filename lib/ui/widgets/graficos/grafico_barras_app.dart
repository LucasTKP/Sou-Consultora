// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Uma barra do gráfico: rótulo embaixo ("Nov"), valor (para a altura) e a
/// descrição lida pelo leitor de tela ("Novembro de 2026: R$ 5.400,00").
class BarraGrafico {
  const BarraGrafico({
    required this.rotulo,
    required this.valor,
    required this.descricao,
  });

  final String rotulo;
  final int valor;
  final String descricao;
}

/// Gráfico de barras simples (sem pacote de gráfico). A barra [destaque] fica
/// na cor primária com [rotuloDestaque] em cima; as outras, em tom suave.
class GraficoBarrasApp extends StatelessWidget {
  const GraficoBarrasApp({
    super.key,
    required this.barras,
    required this.destaque,
    this.rotuloDestaque,
    this.altura = 150,
  });

  final List<BarraGrafico> barras;

  /// Índice da barra em destaque.
  final int destaque;
  final String? rotuloDestaque;
  final double altura;

  /// Barras com valor > 0 ficam com pelo menos esta altura, para aparecer.
  static const _alturaMinima = 4.0;

  @override
  Widget build(BuildContext context) {
    final maior = barras.fold(0, (m, b) => b.valor > m ? b.valor : m);
    return SizedBox(
      height: altura + 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < barras.length; i++)
            Expanded(
              child: _Barra(
                barra: barras[i],
                fracao: maior == 0 ? 0 : barras[i].valor / maior,
                alturaMaxima: altura,
                emDestaque: i == destaque,
                rotuloEmCima: i == destaque ? rotuloDestaque : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.barra,
    required this.fracao,
    required this.alturaMaxima,
    required this.emDestaque,
    this.rotuloEmCima,
  });

  final BarraGrafico barra;
  final double fracao;
  final double alturaMaxima;
  final bool emDestaque;
  final String? rotuloEmCima;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final alturaBarra = barra.valor == 0
        ? 0.0
        : (fracao * alturaMaxima).clamp(
            GraficoBarrasApp._alturaMinima,
            alturaMaxima,
          );
    final cor = emDestaque ? CoresApp.primaria : CoresApp.primariaSuave;
    final topo = rotuloEmCima;
    return Semantics(
      label: barra.descricao,
      selected: emDestaque,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (topo != null)
              FittedBox(
                child: Text(
                  topo,
                  style: estilos.labelSmall?.copyWith(
                    color: CoresApp.primaria,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Container(
              height: alturaBarra,
              decoration: BoxDecoration(
                color: cor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(
                barra.rotulo,
                style: estilos.labelSmall?.copyWith(
                  color: emDestaque
                      ? CoresApp.primaria
                      : CoresApp.sobreSuperficieVariante,
                  fontWeight: emDestaque ? FontWeight.w700 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
