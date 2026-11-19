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
///
/// Cada barra tem uma largura mínima. Se não couberem na tela, o gráfico rola
/// no eixo X e abre mostrando as mais recentes, à direita.
class GraficoBarrasApp extends StatefulWidget {
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

  /// Largura para o mês e o valor caberem sem encolher.
  static const _larguraMinimaBarra = 52.0;

  @override
  State<GraficoBarrasApp> createState() => _GraficoBarrasAppEstado();
}

class _GraficoBarrasAppEstado extends State<GraficoBarrasApp> {
  final _controle = ScrollController();
  var _posicionado = false;

  @override
  void initState() {
    super.initState();
    _agendarFim();
  }

  /// O mês em destaque é o último. A rolagem começa nele.
  void _agendarFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _posicionado || !_controle.hasClients) return;
      final maximo = _controle.position.maxScrollExtent;
      if (maximo <= 0) return;
      _controle.jumpTo(maximo);
      _posicionado = true;
    });
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barras = widget.barras;
    final maior = barras.fold(0, (m, b) => b.valor > m ? b.valor : m);
    final alturaTotal = widget.altura + 44;

    if (barras.isEmpty) return SizedBox(height: alturaTotal);

    return LayoutBuilder(
      builder: (context, limites) {
        final disponivel = limites.maxWidth;
        final minima = barras.length * GraficoBarrasApp._larguraMinimaBarra;
        final cabe = disponivel.isFinite && disponivel > minima;
        final largura = cabe ? disponivel : minima;
        final rola = disponivel.isFinite && !cabe;
        final grafico = SizedBox(
          width: largura.isFinite ? largura : null,
          height: alturaTotal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < barras.length; i++)
                Expanded(
                  child: _Barra(
                    barra: barras[i],
                    fracao: maior == 0 ? 0 : barras[i].valor / maior,
                    alturaMaxima: widget.altura,
                    emDestaque: i == widget.destaque,
                    rotuloEmCima: i == widget.destaque
                        ? widget.rotuloDestaque
                        : null,
                  ),
                ),
            ],
          ),
        );

        if (!rola) return grafico;

        return SizedBox(
          height: alturaTotal,
          child: Scrollbar(
            controller: _controle,
            child: SingleChildScrollView(
              controller: _controle,
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: minima, child: grafico),
            ),
          ),
        );
      },
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
