// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/model/forma_pagamento.dart';
import 'package:sou_consultora/core/model/plano_parcelas.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/vendas/nova/nova_venda_cubit.dart';
import 'package:sou_consultora/ui/modules/vendas/nova/nova_venda_state.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/alternador_segmentado_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/area_texto_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_data_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/interruptor_app.dart';

/// Passo 2: data da venda, como vai pagar, entrada, observação e resumo.
class PassoPagamento extends StatelessWidget {
  const PassoPagamento({
    super.key,
    required this.estado,
    required this.observacoes,
  });

  final NovaVendaState estado;
  final TextEditingController observacoes;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NovaVendaCubit>();
    final estilos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoDataApp(
          rotulo: 'Data da venda',
          obrigatorio: true,
          data: estado.dataVenda,
          ultimaData: DateTime.now(),
          erro: estado.erroData,
          onChanged: cubit.alterarDataVenda,
        ),
        const SizedBox(height: 24),
        Text('Como a cliente vai pagar?', style: estilos.titleMedium),
        const SizedBox(height: 12),
        AlternadorSegmentadoApp<bool>(
          opcoes: const [
            OpcaoSegmento(
              valor: true,
              rotulo: 'À vista',
              icone: Icons.payments_outlined,
            ),
            OpcaoSegmento(
              valor: false,
              rotulo: 'Dividido',
              icone: Icons.calendar_month_outlined,
            ),
          ],
          selecionado: estado.aVista,
          onChanged: cubit.escolherAVista,
        ),
        const SizedBox(height: 16),
        if (estado.aVista && estado.parcelas.isNotEmpty)
          CampoDataApp(
            rotulo: 'Vencimento',
            obrigatorio: true,
            data: estado.parcelas.first.vencimento,
            onChanged: (d) => cubit.alterarVencimento(0, d),
          )
        else
          ..._dividido(context, estado),
        const SizedBox(height: 24),
        InterruptorApp(
          rotulo: 'Já recebeu a 1ª parcela agora?',
          descricao: 'Registra o pagamento junto com a venda.',
          valor: estado.entradaRecebida,
          onChanged: cubit.alterarEntrada,
        ),
        if (estado.entradaRecebida) ...[
          const SizedBox(height: 12),
          AlternadorSegmentadoApp<FormaPagamento>(
            opcoes: const [
              OpcaoSegmento(valor: FormaPagamento.pix, rotulo: 'Pix'),
              OpcaoSegmento(valor: FormaPagamento.cartao, rotulo: 'Cartão'),
              OpcaoSegmento(valor: FormaPagamento.dinheiro, rotulo: 'Dinheiro'),
            ],
            selecionado: estado.formaEntrada,
            onChanged: cubit.alterarFormaEntrada,
          ),
        ],
        const SizedBox(height: 24),
        AreaTextoApp(
          rotulo: 'Observações da venda',
          opcional: true,
          placeholder: 'Ex: Entregar amostra grátis do hidratante...',
          controller: observacoes,
          onChanged: cubit.alterarObservacoes,
        ),
        const SizedBox(height: 24),
        _ResumoPedido(estado: estado),
      ],
    );
  }

  List<Widget> _dividido(BuildContext context, NovaVendaState estado) {
    final cubit = context.read<NovaVendaCubit>();
    final diferenca = estado.diferenca;
    return [
      CampoSelecaoApp<int>(
        rotulo: 'Número de parcelas',
        opcoes: [
          for (
            var n = PlanoParcelas.minimoDividido;
            n <= PlanoParcelas.maximo;
            n++
          )
            n,
        ],
        rotuloDe: (n) => '${n}x',
        valor: estado.parcelas.length,
        onChanged: cubit.alterarQtdParcelas,
      ),
      const SizedBox(height: 16),
      for (var i = 0; i < estado.parcelas.length; i++) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CampoMoedaApp(
                key: ValueKey('valor-$i-${estado.versaoPlano}'),
                rotulo: '${i + 1}ª parcela',
                centavosIniciais: estado.parcelas[i].valor,
                erro: estado.erroValorParcela(i),
                onChanged: (c) => cubit.alterarValorParcela(i, c),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CampoDataApp(
                rotulo: 'Vencimento',
                data: estado.parcelas[i].vencimento,
                onChanged: (d) => cubit.alterarVencimento(i, d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
      if (diferenca != 0)
        Text(
          diferenca > 0
              ? 'Faltam ${FormatadorMoeda.formatar(diferenca)}'
              : 'Sobram ${FormatadorMoeda.formatar(-diferenca)}',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: CoresApp.perigo),
        ),
    ];
  }
}

class _ResumoPedido extends StatelessWidget {
  const _ResumoPedido({required this.estado});

  final NovaVendaState estado;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final qtd = estado.itens.length;
    return CartaoApp(
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Resumo do Pedido', style: estilos.titleMedium),
              ),
              Text(qtd == 1 ? '1 item' : '$qtd itens'),
            ],
          ),
          const Divider(height: 24, color: CoresApp.primariaSuave),
          for (final item in estado.itens)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantidade}x ${item.nome}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(FormatadorMoeda.formatar(item.subtotal)),
                ],
              ),
            ),
          const Divider(color: CoresApp.primariaSuave),
          Row(
            children: [
              const Expanded(child: Text('Total em descontos')),
              Text('- ${FormatadorMoeda.formatar(estado.descontos)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('Total a Cobrar', style: estilos.titleMedium),
              ),
              Text(
                FormatadorMoeda.formatar(estado.total),
                style: estilos.titleLarge?.copyWith(color: CoresApp.primaria),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
