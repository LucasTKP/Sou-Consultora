// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/model/item_venda.dart';
import 'package:sou_consultora/core/model/resumo_cliente.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/servicos/widgets/icone_servico.dart';
import 'package:sou_consultora/ui/modules/vendas/nova/nova_venda_cubit.dart';
import 'package:sou_consultora/ui/modules/vendas/nova/nova_venda_state.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/foto_quadrada_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/erro_em_toast.dart';

/// Passo 1: cliente, itens do pedido e totais.
class PassoItens extends StatelessWidget {
  const PassoItens({
    super.key,
    required this.estado,
    required this.onAdicionar,
    required this.onEditar,
    required this.onNovaCliente,
  });

  final NovaVendaState estado;
  final VoidCallback onAdicionar;
  final ValueChanged<int> onEditar;
  final VoidCallback onNovaCliente;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NovaVendaCubit>();
    final estilos = Theme.of(context).textTheme;
    final qtd = estado.itens.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoSelecaoApp<ResumoCliente>(
          rotulo: 'Cliente',
          obrigatorio: true,
          placeholder: 'Escolha a cliente',
          opcoes: estado.clientes,
          rotuloDe: (c) => c.nome,
          valor: estado.cliente,
          buscavel: true,
          erro: estado.erroCliente,
          icone: Icons.person_outline_rounded,
          onChanged: cubit.alterarCliente,
          onAtalho: onNovaCliente,
          dicaAtalho: 'Cadastrar cliente',
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.shopping_bag_outlined, color: CoresApp.primaria),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Itens do Pedido', style: estilos.titleMedium),
            ),
            Text(qtd == 1 ? '1 item' : '$qtd itens', style: estilos.bodyMedium),
          ],
        ),
        const SizedBox(height: 12),
        BotaoApp.contorno(
          rotulo: 'Adicionar Produto ou Serviço',
          onPressed: onAdicionar,
        ),
        ErroEmToast(erro: estado.erroItens),
        const SizedBox(height: 12),
        for (var i = 0; i < estado.itens.length; i++) ...[
          _CartaoItem(
            item: estado.itens[i],
            onEditar: () => onEditar(i),
            onRemover: () => cubit.removerItem(i),
          ),
          const SizedBox(height: 12),
        ],
        if (estado.itens.isNotEmpty) _Totais(estado: estado),
      ],
    );
  }
}

class _CartaoItem extends StatelessWidget {
  const _CartaoItem({
    required this.item,
    required this.onEditar,
    required this.onRemover,
  });

  final ItemPedido item;
  final VoidCallback onEditar;
  final VoidCallback onRemover;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return CartaoApp(
      filho: Row(
        children: [
          if (item.tipo == TipoItem.servico)
            IconeServico(
              categoria: item.categoriaServico ?? '',
              urlFoto: item.urlFoto,
              tamanho: TamanhoAvatar.miniatura,
            )
          else
            FotoQuadradaApp(
              url: item.urlFoto,
              tamanho: TamanhoAvatar.miniatura,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: estilos.titleSmall,
                ),
                Text(
                  '${item.quantidade}x • Desconto: '
                  '${FormatadorMoeda.formatar(item.desconto)}',
                  style: estilos.bodySmall,
                ),
                Text(
                  FormatadorMoeda.formatar(item.subtotal),
                  style: estilos.titleSmall?.copyWith(color: CoresApp.primaria),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Alterar ${item.nome}',
            onPressed: onEditar,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Remover ${item.nome}',
            onPressed: onRemover,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _Totais extends StatelessWidget {
  const _Totais({required this.estado});

  final NovaVendaState estado;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CoresApp.primariaSuave.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _linha(
              'Subtotal original',
              FormatadorMoeda.formatar(estado.subtotal),
              null,
            ),
            const SizedBox(height: 4),
            _linha(
              'Descontos nos itens',
              '- ${FormatadorMoeda.formatar(estado.descontos)}',
              estilos.bodyMedium?.copyWith(color: CoresApp.primaria),
            ),
            const Divider(color: CoresApp.primariaSuave),
            _linha(
              'Total dos itens',
              FormatadorMoeda.formatar(estado.total),
              estilos.titleLarge?.copyWith(color: CoresApp.primaria),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linha(String rotulo, String valor, TextStyle? estilo) => Row(
    children: [
      Expanded(child: Text(rotulo)),
      Text(valor, style: estilo),
    ],
  );
}
