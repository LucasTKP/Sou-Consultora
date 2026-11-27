// ignore_for_file: deprecated_member_use
import 'package:sou_consultora/ui/widgets/estrutura/rodape_seguro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/core/model/detalhe_parcela.dart';
import 'package:sou_consultora/core/model/pagamento.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/ui/formatadores/formatador_telefone.dart';
import 'package:sou_consultora/ui/modules/a_receber/parcela/a_receber_parcela_cubit.dart';
import 'package:sou_consultora/ui/modules/a_receber/parcela/a_receber_parcela_state.dart';
import 'package:sou_consultora/ui/modules/a_receber/parcela/widgets/cartao_saldo_parcela.dart';
import 'package:sou_consultora/ui/modules/a_receber/parcela/widgets/folha_registrar_pagamento.dart';
import 'package:sou_consultora/ui/modules/a_receber/parcela/widgets/secao_pagamentos_parcela.dart';
import 'package:sou_consultora/ui/modules/a_receber/parcela/widgets/secao_venda_parcela.dart';
import 'package:sou_consultora/ui/modules/vendas/widgets/folha_opcoes_venda.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';

/// Detalhes de uma parcela: saldo, cliente (Cobrar), pagamentos, a venda e
/// as outras parcelas; Pagar (com saldo) e Mais opções.
class AReceberParcelaScreen extends StatelessWidget {
  const AReceberParcelaScreen({super.key, required this.idParcela});

  final String idParcela;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AReceberParcelaCubit(idParcela: idParcela),
      child: const _ParcelaVista(),
    );
  }
}

class _ParcelaVista extends StatelessWidget {
  const _ParcelaVista();

  void _aoMudarEstado(BuildContext context, AReceberParcelaState estado) {
    final aviso = estado.aviso;
    if (aviso == null) return;
    ToastApp.mostrar(context, aviso);
    context.read<AReceberParcelaCubit>().limparAviso();
  }

  Future<void> _pagar(BuildContext context, AReceberParcelaState estado) async {
    final cubit = context.read<AReceberParcelaCubit>();
    final idPagamento = await FolhaRegistrarPagamento.mostrar(
      context,
      cubit: cubit,
      saldo: estado.detalhe!.parcela.saldo,
      hoje: estado.hoje,
    );
    if (idPagamento == null || !context.mounted) return;
    await _abrirComprovante(context, idPagamento: idPagamento);
  }

  /// Corrige um pagamento anotado errado: valor, forma, data e observação.
  Future<void> _editarPagamento(
    BuildContext context,
    AReceberParcelaState estado,
    Pagamento pagamento,
  ) async {
    final cubit = context.read<AReceberParcelaCubit>();
    final saldoMaximo = estado.detalhe!.parcela.saldo + pagamento.valor;
    await FolhaRegistrarPagamento.mostrar(
      context,
      cubit: cubit,
      saldo: saldoMaximo,
      hoje: estado.hoje,
      pagamento: pagamento,
    );
  }

  /// Sem [idPagamento], o comprovante mostra o último pagamento da parcela.
  Future<void> _abrirComprovante(
    BuildContext context, {
    String? idPagamento,
  }) async {
    final cubit = context.read<AReceberParcelaCubit>();
    await context.push(
      RotasApp.comprovanteParcela(cubit.idParcela, idPagamento: idPagamento),
    );
    await cubit.carregar();
  }

  Future<void> _abrirVenda(BuildContext context, String idVenda) async {
    final cubit = context.read<AReceberParcelaCubit>();
    final cancelou = await context.push<bool>(RotasApp.detalhesVenda(idVenda));
    if (!context.mounted) return;
    // A venda foi cancelada lá: esta parcela deixou de existir.
    if (cancelou == true) {
      Navigator.of(context).pop(true);
      return;
    }
    await cubit.carregar();
  }

  Future<void> _abrirParcela(BuildContext context, String id) async {
    final cubit = context.read<AReceberParcelaCubit>();
    await context.push(RotasApp.detalhesParcela(id));
    await cubit.carregar();
  }

  /// O pagamento mais recente desta parcela, quando há o que corrigir.
  static Pagamento? _pagamentoMaisRecente(DetalheParcela detalhe) {
    final lista = detalhe.pagamentos;
    if (lista.isEmpty) return null;
    return lista.reduce((a, b) => a.data.isAfter(b.data) ? a : b);
  }

  Future<void> _opcoes(BuildContext context, DetalheParcela detalhe) async {
    final cubit = context.read<AReceberParcelaCubit>();
    final pagamento = _pagamentoMaisRecente(detalhe);
    final opcao = await FolhaOpcoesVenda.mostrar(
      context,
      podeEditar: pagamento != null,
      podeCobrar: !detalhe.parcela.paga,
      temRecibo: detalhe.ultimoPagamento != null,
      podeCancelar: false,
    );
    if (!context.mounted) return;
    switch (opcao) {
      case null:
        return;
      case OpcaoVenda.editar:
        final alvo = pagamento;
        if (alvo == null) return;
        await _editarPagamento(context, cubit.state, alvo);
      case OpcaoVenda.cobrar:
        await cubit.cobrar();
      case OpcaoVenda.recibo:
        await _abrirComprovante(context);
      case OpcaoVenda.cancelar:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AReceberParcelaCubit, AReceberParcelaState>(
      listenWhen: (antes, depois) => antes.aviso != depois.aviso,
      listener: _aoMudarEstado,
      builder: (context, estado) {
        final parcela = estado.detalhe?.parcela;
        return Scaffold(
          body: Column(
            children: [
              CabecalhoApp(
                titulo: 'Detalhes da Parcela',
                subtitulo: parcela == null
                    ? null
                    : 'Parcela ${parcela.textoNumero}',
              ),
              Expanded(child: _corpo(context, estado)),
              if (estado.detalhe != null) _rodape(context, estado),
            ],
          ),
        );
      },
    );
  }

  Widget _corpo(BuildContext context, AReceberParcelaState estado) {
    final detalhe = estado.detalhe;
    if (detalhe != null) {
      return _Conteudo(
        detalhe: detalhe,
        hoje: estado.hoje,
        onCobrar: context.read<AReceberParcelaCubit>().cobrar,
        onVenda: () => _abrirVenda(context, detalhe.venda.id),
        onParcela: (id) => _abrirParcela(context, id),
        onEditarPagamento: (pagamento) =>
            _editarPagamento(context, estado, pagamento),
      );
    }
    final erro = estado.erro;
    if (erro != null) {
      return EstadoErroApp(
        mensagem: erro,
        onTentarNovamente: context.read<AReceberParcelaCubit>().carregar,
      );
    }
    return const EstadoCarregandoApp();
  }

  Widget _rodape(BuildContext context, AReceberParcelaState estado) {
    final detalhe = estado.detalhe!;
    return RodapeSeguro(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!detalhe.parcela.paga) ...[
            BotaoApp(rotulo: 'Pagar', onPressed: () => _pagar(context, estado)),
            const SizedBox(height: 12),
          ],
          BotaoApp.secundario(
            rotulo: 'Mais opções',
            onPressed: () => _opcoes(context, detalhe),
          ),
        ],
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({
    required this.detalhe,
    required this.hoje,
    required this.onCobrar,
    required this.onVenda,
    required this.onParcela,
    required this.onEditarPagamento,
  });

  final DetalheParcela detalhe;
  final DateTime hoje;
  final VoidCallback onCobrar;
  final VoidCallback onVenda;
  final ValueChanged<String> onParcela;
  final ValueChanged<Pagamento> onEditarPagamento;

  @override
  Widget build(BuildContext context) {
    final parcela = detalhe.parcela;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        CartaoSaldoParcela(parcela: parcela, hoje: hoje),
        const SizedBox(height: 16),
        _CartaoCliente(parcela: parcela, onCobrar: onCobrar),
        const SizedBox(height: 24),
        SecaoPagamentosParcela(
          parcela: parcela,
          pagamentos: detalhe.pagamentos,
          hoje: hoje,
          onEditar: onEditarPagamento,
        ),
        const SizedBox(height: 24),
        SecaoVendaParcela(
          venda: detalhe.venda,
          parcelas: detalhe.parcelasDaVenda,
          idAtual: parcela.id,
          hoje: hoje,
          onVenda: onVenda,
          onParcela: onParcela,
        ),
      ],
    );
  }
}

class _CartaoCliente extends StatelessWidget {
  const _CartaoCliente({required this.parcela, required this.onCobrar});

  final ResumoParcela parcela;
  final VoidCallback onCobrar;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return CartaoApp(
      filho: Row(
        children: [
          AvatarApp(
            iniciais: Cliente.iniciaisDe(parcela.clienteNome),
            tamanho: TamanhoAvatar.card,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parcela.clienteNome, style: estilos.titleMedium),
                Text(
                  FormatadorTelefone.formatar(parcela.clienteWhatsapp),
                  style: estilos.bodySmall,
                ),
              ],
            ),
          ),
          if (!parcela.paga) ...[
            const SizedBox(width: 8),
            BotaoApp.contorno(
              rotulo: 'Cobrar',
              tamanho: TamanhoBotao.compacto,
              expande: false,
              onPressed: onCobrar,
            ),
          ],
        ],
      ),
    );
  }
}
