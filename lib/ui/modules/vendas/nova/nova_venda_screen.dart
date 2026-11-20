// ignore_for_file: deprecated_member_use
import 'package:sou_consultora/ui/widgets/estrutura/rodape_seguro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/ui/modules/vendas/nova/nova_venda_cubit.dart';
import 'package:sou_consultora/ui/modules/vendas/nova/nova_venda_state.dart';
import 'package:sou_consultora/ui/modules/vendas/nova/widgets/folha_item_venda.dart';
import 'package:sou_consultora/ui/modules/vendas/nova/widgets/passo_itens.dart';
import 'package:sou_consultora/ui/modules/vendas/nova/widgets/passo_pagamento.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/dialogo_confirmacao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';

/// Nova venda (com [clienteInicialId] opcional) ou edição ([idVenda]).
/// Ao concluir, fecha devolvendo o id da venda.
class NovaVendaScreen extends StatelessWidget {
  const NovaVendaScreen({super.key, this.idVenda, this.clienteInicialId});

  final String? idVenda;
  final String? clienteInicialId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          NovaVendaCubit(idVenda: idVenda, clienteInicialId: clienteInicialId),
      child: const _NovaVendaVista(),
    );
  }
}

class _NovaVendaVista extends StatefulWidget {
  const _NovaVendaVista();

  @override
  State<_NovaVendaVista> createState() => _NovaVendaVistaState();
}

class _NovaVendaVistaState extends State<_NovaVendaVista> {
  final _observacoes = TextEditingController();

  NovaVendaCubit get _cubit => context.read<NovaVendaCubit>();

  @override
  void dispose() {
    _observacoes.dispose();
    super.dispose();
  }

  Future<void> _adicionar() async {
    final item = await FolhaItemVenda.mostrar(
      context,
      produtos: () => _cubit.state.produtos,
      servicos: () => _cubit.state.servicos,
      onNovoProduto: _novoProduto,
      onNovoServico: _novoServico,
      jaNoPedido: (chave) => _cubit.jaNoPedido(chave),
    );
    if (item != null) _cubit.adicionarItem(item);
  }

  Future<void> _editar(int indice) async {
    final estado = _cubit.state;
    final item = await FolhaItemVenda.mostrar(
      context,
      produtos: () => _cubit.state.produtos,
      servicos: () => _cubit.state.servicos,
      onNovoProduto: _novoProduto,
      onNovoServico: _novoServico,
      jaNoPedido: (chave) => _cubit.jaNoPedido(chave, indiceEditado: indice),
      item: estado.itens[indice],
    );
    if (item != null) _cubit.substituirItem(indice, item);
  }

  Future<void> _novaCliente() async {
    // A cliente nova chega ao cubit pelo repositório de clientes.
    await context.push(RotasApp.novoCliente);
  }

  Future<void> _novoProduto() async {
    // O produto novo chega ao cubit pelo repositório de produtos.
    await context.push(RotasApp.novoProduto);
  }

  Future<void> _novoServico() async {
    await context.push(RotasApp.novoServico);
  }

  /// Passo 2 → passo 1; no passo 1, confirma o descarte se houver itens.
  Future<void> _voltar() async {
    if (_cubit.state.passo == 2) {
      _cubit.voltar();
      return;
    }
    if (_cubit.state.itens.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final descartar = await DialogoConfirmacaoApp.mostrar(
      context: context,
      titulo: 'Descartar o pedido?',
      mensagem: 'Os itens deste pedido ainda não foram salvos.',
      rotuloConfirmar: 'Descartar',
      rotuloCancelar: 'Continuar editando',
      perigo: true,
    );
    if (descartar && mounted) Navigator.of(context).pop();
  }

  void _aoMudarEstado(BuildContext context, NovaVendaState estado) {
    final id = estado.idSalvo;
    if (id != null) {
      Navigator.of(context).pop(id);
      return;
    }
    final aviso = estado.aviso;
    if (aviso == null) return;
    ToastApp.mostrar(context, aviso);
    _cubit.limparAviso();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<NovaVendaCubit, NovaVendaState>(
          listenWhen: (antes, depois) =>
              antes.versaoPreenchimento != depois.versaoPreenchimento,
          listener: (_, estado) => _observacoes.text = estado.observacoes,
        ),
        BlocListener<NovaVendaCubit, NovaVendaState>(
          listenWhen: (antes, depois) =>
              antes.aviso != depois.aviso || antes.idSalvo != depois.idSalvo,
          listener: _aoMudarEstado,
        ),
      ],
      child: BlocBuilder<NovaVendaCubit, NovaVendaState>(
        builder: (context, estado) => PopScope(
          canPop: estado.passo == 1 && estado.itens.isEmpty,
          onPopInvokedWithResult: (saiu, _) {
            if (!saiu) _voltar();
          },
          child: Scaffold(
            body: Column(
              children: [
                CabecalhoApp(
                  titulo: estado.editando ? 'Editar Venda' : 'Nova Venda',
                  subtitulo:
                      'Passo ${estado.passo} de ${NovaVendaState.totalPassos}',
                  onVoltar: _voltar,
                ),
                Expanded(child: _corpo(estado)),
                if (!estado.carregando && estado.erroCarregar == null)
                  _Rodape(estado: estado),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _corpo(NovaVendaState estado) {
    if (estado.carregando) {
      return const EstadoCarregandoApp(mensagem: 'Carregando dados...');
    }
    final erro = estado.erroCarregar;
    if (erro != null) {
      return EstadoErroApp(mensagem: erro, onTentarNovamente: _cubit.carregar);
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (estado.passo == 1)
          PassoItens(
            estado: estado,
            onAdicionar: _adicionar,
            onEditar: _editar,
            onNovaCliente: _novaCliente,
          )
        else
          PassoPagamento(estado: estado, observacoes: _observacoes),
      ],
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({required this.estado});

  final NovaVendaState estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NovaVendaCubit>();
    return RodapeSeguro(
      child: estado.passo == 1
          ? BotaoApp(
              rotulo: 'Avançar',
              iconeFim: const Icon(Icons.arrow_forward_rounded),
              onPressed: cubit.avancar,
            )
          : BotaoApp(
              rotulo: estado.salvando
                  ? 'Salvando...'
                  : estado.editando
                  ? 'Salvar Venda'
                  : 'Concluir Venda',
              onPressed: estado.podeConcluir ? cubit.concluir : null,
            ),
    );
  }
}
