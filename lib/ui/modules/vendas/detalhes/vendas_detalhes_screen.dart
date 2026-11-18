// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/core/model/detalhe_venda.dart';
import 'package:sou_consultora/core/model/item_venda.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/servicos/widgets/icone_servico.dart';
import 'package:sou_consultora/ui/modules/vendas/detalhes/vendas_detalhes_cubit.dart';
import 'package:sou_consultora/ui/modules/vendas/detalhes/vendas_detalhes_state.dart';
import 'package:sou_consultora/ui/modules/vendas/widgets/folha_opcoes_venda.dart';
import 'package:sou_consultora/ui/modules/vendas/widgets/selos_venda.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/foto_quadrada_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/dialogo_confirmacao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';

/// Detalhes de uma venda: itens, parcelas, editar (sem pagamento) e opções.
class VendasDetalhesScreen extends StatelessWidget {
  const VendasDetalhesScreen({super.key, required this.idVenda});

  final String idVenda;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendasDetalhesCubit(idVenda: idVenda),
      child: const _DetalhesVista(),
    );
  }
}

class _DetalhesVista extends StatelessWidget {
  const _DetalhesVista();

  void _aoMudarEstado(BuildContext context, VendasDetalhesState estado) {
    if (estado.cancelada) {
      Navigator.of(context).pop(true);
      return;
    }
    final aviso = estado.aviso;
    if (aviso == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(aviso), behavior: SnackBarBehavior.floating),
      );
    context.read<VendasDetalhesCubit>().limparAviso();
  }

  Future<void> _editar(BuildContext context, String id) async {
    final cubit = context.read<VendasDetalhesCubit>();
    final salvou = await context.push<String>(RotasApp.editarVenda(id));
    if (salvou != null) await cubit.carregar();
  }

  Future<void> _abrirParcela(BuildContext context, String id) async {
    final cubit = context.read<VendasDetalhesCubit>();
    await context.push(RotasApp.detalhesParcela(id));
    await cubit.carregar();
  }

  Future<void> _opcoes(BuildContext context, DetalheVenda detalhe) async {
    final cubit = context.read<VendasDetalhesCubit>();
    final ultimaPaga = _ultimaComPagamento(detalhe.parcelas);
    final opcao = await FolhaOpcoesVenda.mostrar(
      context,
      podeCobrar: detalhe.proximaEmAberto != null,
      temRecibo: ultimaPaga != null,
    );
    if (!context.mounted) return;
    switch (opcao) {
      case null:
        return;
      case OpcaoVenda.cobrar:
        await cubit.cobrar();
      case OpcaoVenda.recibo:
        await context.push(RotasApp.comprovanteParcela(ultimaPaga!.id));
      case OpcaoVenda.cancelar:
        await _confirmarCancelamento(context);
    }
  }

  Future<void> _confirmarCancelamento(BuildContext context) async {
    final cubit = context.read<VendasDetalhesCubit>();
    final confirmou = await DialogoConfirmacaoApp.mostrar(
      context: context,
      titulo: 'Cancelar esta venda?',
      mensagem:
          'Isso apaga a venda, as parcelas e os pagamentos, '
          'e devolve os produtos ao estoque.',
      rotuloConfirmar: 'Cancelar venda',
      rotuloCancelar: 'Voltar',
      perigo: true,
    );
    if (confirmou) await cubit.cancelar();
  }

  static ResumoParcela? _ultimaComPagamento(List<ResumoParcela> parcelas) {
    ResumoParcela? ultima;
    for (final p in parcelas) {
      final momento = p.ultimoPagamento;
      if (momento == null) continue;
      if (ultima == null || momento.isAfter(ultima.ultimoPagamento!)) {
        ultima = p;
      }
    }
    return ultima;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VendasDetalhesCubit, VendasDetalhesState>(
      listenWhen: (antes, depois) =>
          antes.aviso != depois.aviso || antes.cancelada != depois.cancelada,
      listener: _aoMudarEstado,
      builder: (context, estado) {
        final detalhe = estado.detalhe;
        return Scaffold(
          body: Column(
            children: [
              const CabecalhoApp(titulo: 'Detalhes da Venda'),
              Expanded(child: _corpo(context, estado)),
              if (detalhe != null)
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (detalhe.venda.podeEditar) ...[
                        BotaoApp(
                          rotulo: 'Editar Venda',
                          iconeInicio: const Icon(Icons.edit_outlined),
                          onPressed: () => _editar(context, detalhe.venda.id),
                        ),
                        const SizedBox(height: 12),
                      ],
                      BotaoApp.secundario(
                        rotulo: estado.processando
                            ? 'Cancelando...'
                            : 'Mais opções',
                        iconeInicio: const Icon(Icons.more_horiz_rounded),
                        onPressed: estado.processando
                            ? null
                            : () => _opcoes(context, detalhe),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _corpo(BuildContext context, VendasDetalhesState estado) {
    final detalhe = estado.detalhe;
    if (detalhe != null) {
      return _Conteudo(
        estado: estado,
        detalhe: detalhe,
        onParcela: (id) => _abrirParcela(context, id),
      );
    }
    final erro = estado.erro;
    if (erro != null) {
      return EstadoErroApp(
        mensagem: erro,
        onTentarNovamente: context.read<VendasDetalhesCubit>().carregar,
      );
    }
    return const EstadoCarregandoApp();
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({
    required this.estado,
    required this.detalhe,
    required this.onParcela,
  });

  final VendasDetalhesState estado;
  final DetalheVenda detalhe;
  final ValueChanged<String> onParcela;

  @override
  Widget build(BuildContext context) {
    final venda = detalhe.venda;
    final estilos = Theme.of(context).textTheme;
    final cubit = context.read<VendasDetalhesCubit>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Row(
          children: [
            AvatarApp(iniciais: Cliente.iniciaisDe(venda.clienteNome)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(venda.clienteNome, style: estilos.titleMedium),
                  Text(
                    '${FormatadorData.porExtenso(venda.dataVenda)} • '
                    '${venda.codigoTexto}',
                    style: estilos.bodySmall,
                  ),
                ],
              ),
            ),
            SeloStatusVenda(status: venda.status),
          ],
        ),
        const SizedBox(height: 16),
        _Abas(
          selecionada: estado.aba,
          qtdItens: detalhe.itens.length,
          qtdParcelas: detalhe.parcelas.length,
          onChanged: cubit.alterarAba,
        ),
        const SizedBox(height: 16),
        if (estado.aba == AbaVenda.itens) ...[
          for (final item in detalhe.itens) ...[
            _CartaoItem(item: item),
            const SizedBox(height: 12),
          ],
          _ResumoValores(detalhe: detalhe),
          if (venda.observacoes != null) ...[
            const SizedBox(height: 16),
            CartaoApp(
              titulo: const Text('Observações'),
              filho: Text(venda.observacoes!),
            ),
          ],
        ] else
          for (final parcela in detalhe.parcelas) ...[
            _CartaoParcela(
              parcela: parcela,
              hoje: estado.hoje,
              onTap: () => onParcela(parcela.id),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _Abas extends StatelessWidget {
  const _Abas({
    required this.selecionada,
    required this.qtdItens,
    required this.qtdParcelas,
    required this.onChanged,
  });

  final AbaVenda selecionada;
  final int qtdItens;
  final int qtdParcelas;
  final ValueChanged<AbaVenda> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _aba(
            context,
            AbaVenda.itens,
            Icons.shopping_bag_outlined,
            'Itens $qtdItens',
          ),
        ),
        Expanded(
          child: _aba(
            context,
            AbaVenda.pagamento,
            Icons.payments_outlined,
            'Pagamento $qtdParcelas',
          ),
        ),
      ],
    );
  }

  Widget _aba(
    BuildContext context,
    AbaVenda aba,
    IconData icone,
    String rotulo,
  ) {
    final ativa = aba == selecionada;
    final cor = ativa ? CoresApp.primaria : CoresApp.sobreSuperficieVariante;
    return Semantics(
      selected: ativa,
      button: true,
      child: InkWell(
        onTap: () => onChanged(aba),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: ativa ? CoresApp.primaria : CoresApp.primariaSuave,
                width: ativa ? 3 : 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: cor, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: cor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoItem extends StatelessWidget {
  const _CartaoItem({required this.item});

  final ItemVendido item;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final encomenda = item.tipo == TipoItem.produto && !item.baixarEstoque;
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
                Text(item.nome, style: estilos.titleSmall),
                Text(
                  '${item.quantidade}x • Desconto: '
                  '${FormatadorMoeda.formatar(item.desconto)}'
                  '${encomenda ? ' • Encomenda' : ''}',
                  style: estilos.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            FormatadorMoeda.formatar(item.subtotal),
            style: estilos.titleSmall?.copyWith(color: CoresApp.primaria),
          ),
        ],
      ),
    );
  }
}

class _ResumoValores extends StatelessWidget {
  const _ResumoValores({required this.detalhe});

  final DetalheVenda detalhe;

  @override
  Widget build(BuildContext context) {
    final venda = detalhe.venda;
    final estilos = Theme.of(context).textTheme;
    return CartaoApp(
      titulo: const Text('Resumo dos Valores'),
      filho: Column(
        children: [
          _linha(
            'Subtotal dos itens',
            FormatadorMoeda.formatar(venda.subtotal),
            null,
          ),
          _linha(
            'Descontos aplicados',
            FormatadorMoeda.formatar(venda.totalDescontos),
            null,
          ),
          const Divider(color: CoresApp.primariaSuave),
          _linha(
            'Total Geral',
            FormatadorMoeda.formatar(venda.total),
            estilos.titleLarge?.copyWith(color: CoresApp.primaria),
          ),
        ],
      ),
    );
  }

  Widget _linha(String rotulo, String valor, TextStyle? estilo) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(rotulo)),
        Text(valor, style: estilo),
      ],
    ),
  );
}

class _CartaoParcela extends StatelessWidget {
  const _CartaoParcela({
    required this.parcela,
    required this.hoje,
    required this.onTap,
  });

  final ResumoParcela parcela;
  final DateTime hoje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final status = parcela.status(hoje: hoje);
    return Semantics(
      button: true,
      label: 'Parcela ${parcela.textoNumero}',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: CartaoApp(
          filho: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Parcela ${parcela.textoNumero}',
                      style: estilos.titleMedium,
                    ),
                  ),
                  SeloStatusParcela(status: status),
                ],
              ),
              const Divider(height: 24, color: CoresApp.primariaSuave),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Vencimento: ${FormatadorData.curta(parcela.vencimento)}',
                      style: estilos.bodySmall,
                    ),
                  ),
                  Text(
                    FormatadorMoeda.formatar(parcela.valor),
                    style: estilos.titleMedium?.copyWith(
                      color: CoresApp.primaria,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: CoresApp.primaria,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
