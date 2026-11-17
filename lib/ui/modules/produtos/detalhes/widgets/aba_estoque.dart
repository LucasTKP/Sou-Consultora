// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/model/lote_produto.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/produtos/detalhes/produtos_detalhes_cubit.dart';
import 'package:sou_consultora/ui/modules/produtos/detalhes/produtos_detalhes_state.dart';
import 'package:sou_consultora/ui/modules/produtos/detalhes/widgets/cartao_lote.dart';
import 'package:sou_consultora/ui/modules/produtos/detalhes/widgets/cartao_saida.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/dialogo_confirmacao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/alternador_segmentado_app.dart';

/// Aba Estoque: resumo, entradas (lotes) e saídas (vendas).
/// Os itens voltam como lista para entrar no `ListView` dos detalhes.
abstract final class AbaEstoque {
  static List<Widget> itens(
    BuildContext context,
    ProdutosDetalhesState estado,
  ) {
    if (estado.carregandoEstoque) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: EstadoCarregandoApp(mensagem: 'Carregando estoque...'),
        ),
      ];
    }
    final erro = estado.erroEstoque;
    if (erro != null) {
      return [
        SizedBox(
          height: 280,
          child: EstadoErroApp(
            mensagem: erro,
            onTentarNovamente: context
                .read<ProdutosDetalhesCubit>()
                .carregarEstoque,
          ),
        ),
      ];
    }
    final cubit = context.read<ProdutosDetalhesCubit>();
    return [
      _CartaoResumo(estado: estado),
      const SizedBox(height: 16),
      AlternadorSegmentadoApp<SegmentoEstoque>(
        opcoes: const [
          OpcaoSegmento(
            valor: SegmentoEstoque.entradas,
            rotulo: 'Entradas',
            icone: Icons.login_rounded,
          ),
          OpcaoSegmento(
            valor: SegmentoEstoque.saidas,
            rotulo: 'Saídas',
            icone: Icons.logout_rounded,
          ),
        ],
        selecionado: estado.segmento,
        onChanged: cubit.alterarSegmento,
      ),
      const SizedBox(height: 16),
      ...switch (estado.segmento) {
        SegmentoEstoque.entradas => _entradas(context, estado),
        SegmentoEstoque.saidas => _saidas(estado),
      },
    ];
  }

  static List<Widget> _entradas(
    BuildContext context,
    ProdutosDetalhesState estado,
  ) {
    if (estado.lotes.isEmpty) {
      return const [
        _Vazio(
          'Nenhum lote ainda. Toque em Lançar Estoque para registrar uma compra.',
        ),
      ];
    }
    return [
      for (final lote in estado.lotes) ...[
        CartaoLote(
          lote: lote,
          onApagar: lote.podeApagar ? () => _apagar(context, lote) : null,
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  static List<Widget> _saidas(ProdutosDetalhesState estado) {
    if (estado.saidas.isEmpty) return const [_Vazio('Nenhuma venda ainda')];
    return [
      for (final saida in estado.saidas) ...[
        CartaoSaida(saida: saida),
        const SizedBox(height: 12),
      ],
    ];
  }

  static Future<void> _apagar(BuildContext context, LoteProduto lote) async {
    final cubit = context.read<ProdutosDetalhesCubit>();
    final confirmou = await DialogoConfirmacaoApp.mostrar(
      context: context,
      titulo: 'Apagar o lote ${lote.rotulo}?',
      mensagem:
          'As ${lote.quantidade} unidades deste lote saem do estoque. '
          'Use quando o lançamento foi feito por engano.',
      rotuloConfirmar: 'Apagar lote',
      perigo: true,
    );
    if (confirmou) await cubit.apagarLote(lote.id);
  }
}

class _CartaoResumo extends StatelessWidget {
  const _CartaoResumo({required this.estado});

  final ProdutosDetalhesState estado;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final resumo = estado.resumoEstoque;
    return CartaoApp(
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: CoresApp.primaria,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo disponível', style: estilos.bodySmall),
                    Text(
                      resumo.saldo == 1
                          ? '1 unidade'
                          : '${resumo.saldo} unidades',
                      style: estilos.titleLarge,
                    ),
                  ],
                ),
              ),
              SeloStatusApp(
                rotulo: resumo.prontaEntrega ? 'Pronta entrega' : 'Esgotado',
                status: resumo.prontaEntrega
                    ? StatusSelo.sucesso
                    : StatusSelo.perigo,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Numero(
                  rotulo: 'Custo médio',
                  valor: FormatadorMoeda.formatar(resumo.custoMedio),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Numero(
                  rotulo: 'Valor em estoque',
                  valor: FormatadorMoeda.formatar(resumo.valorEmEstoque),
                  destaque: true,
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
  const _Numero({
    required this.rotulo,
    required this.valor,
    this.destaque = false,
  });

  final String rotulo;
  final String valor;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CoresApp.primariaSuave.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rotulo, style: estilos.bodySmall),
            Text(
              valor,
              style: estilos.titleSmall?.copyWith(
                color: destaque ? CoresApp.primaria : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: CoresApp.sobreSuperficieVariante),
      ),
    );
  }
}
