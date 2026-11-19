// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/item_lancamento.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/produtos/lancar_estoque/lancar_estoque_cubit.dart';
import 'package:sou_consultora/ui/modules/produtos/lancar_estoque/lancar_estoque_state.dart';
import 'package:sou_consultora/ui/modules/produtos/lancar_estoque/widgets/cartao_item_compra.dart';
import 'package:sou_consultora/ui/modules/produtos/lancar_estoque/widgets/folha_item_estoque.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/dialogo_confirmacao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_data_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';
import 'package:sou_consultora/ui/temas/espacos_app.dart';

/// Lançar Estoque: uma compra com data e produtos. Ao salvar, fecha devolvendo
/// `true`. Com [produtoInicialId], a folha de item já abre com o produto.
class LancarEstoqueScreen extends StatelessWidget {
  const LancarEstoqueScreen({super.key, this.produtoInicialId});

  final String? produtoInicialId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LancarEstoqueCubit(produtoInicialId: produtoInicialId),
      child: const _LancarEstoqueVista(),
    );
  }
}

class _LancarEstoqueVista extends StatefulWidget {
  const _LancarEstoqueVista();

  @override
  State<_LancarEstoqueVista> createState() => _LancarEstoqueVistaState();
}

class _LancarEstoqueVistaState extends State<_LancarEstoqueVista> {
  LancarEstoqueCubit get _cubit => context.read<LancarEstoqueCubit>();

  @override
  void initState() {
    super.initState();
    // Com os produtos já em cache, o cubit fica pronto antes do listener.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _abrirProdutoInicial(context, _cubit.state);
    });
  }

  Future<void> _abrirFolha({int? indice, ResumoProduto? produtoInicial}) async {
    final estado = _cubit.state;
    final item = indice == null ? null : estado.itens[indice];
    final escolha = await FolhaItemEstoque.mostrar(
      context,
      produtos: estado.produtos,
      dataCompra: estado.dataCompra,
      jaNaCompra: (id) => _cubit.jaNaCompra(id, indiceEditado: indice),
      item: item,
      produtoInicial: produtoInicial,
    );
    switch (escolha) {
      case null:
        return;
      case ItemConfirmado(item: final novo) when indice == null:
        _cubit.adicionarItem(novo);
      case ItemConfirmado(item: final novo):
        _cubit.substituirItem(indice!, novo);
      case ItemRemovido():
        if (indice != null) _cubit.removerItem(indice);
    }
  }

  Future<void> _cadastrarProduto() async {
    // O produto novo chega ao cubit pelo repositório de produtos.
    await context.push(RotasApp.novoProduto);
  }

  Future<void> _sair() async {
    if (_cubit.state.itens.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final descartar = await DialogoConfirmacaoApp.mostrar(
      context: context,
      titulo: 'Descartar lançamento?',
      mensagem: 'Os produtos desta compra ainda não foram salvos.',
      rotuloConfirmar: 'Descartar',
      rotuloCancelar: 'Continuar editando',
      perigo: true,
    );
    if (descartar && mounted) Navigator.of(context).pop();
  }

  void _aoMudarEstado(BuildContext context, LancarEstoqueState estado) {
    if (estado.salvo) {
      Navigator.of(context).pop(true);
      return;
    }
    final aviso = estado.aviso;
    if (aviso == null) return;
    ToastApp.mostrar(context, aviso);
    _cubit.limparAviso();
  }

  /// Vindo do produto: assim que os produtos chegam, abre a folha com ele.
  void _abrirProdutoInicial(BuildContext context, LancarEstoqueState estado) {
    final produto = estado.produtoInicial;
    if (produto == null) return;
    _cubit.consumirProdutoInicial();
    _abrirFolha(produtoInicial: produto);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LancarEstoqueCubit, LancarEstoqueState>(
          listenWhen: (antes, depois) =>
              antes.aviso != depois.aviso || antes.salvo != depois.salvo,
          listener: _aoMudarEstado,
        ),
        BlocListener<LancarEstoqueCubit, LancarEstoqueState>(
          listenWhen: (antes, depois) =>
              antes.produtoInicial == null && depois.produtoInicial != null,
          listener: _abrirProdutoInicial,
        ),
      ],
      child: BlocBuilder<LancarEstoqueCubit, LancarEstoqueState>(
        builder: (context, estado) => PopScope(
          canPop: estado.itens.isEmpty,
          onPopInvokedWithResult: (saiu, _) {
            if (!saiu) _sair();
          },
          child: Scaffold(
            body: Column(
              children: [
                CabecalhoApp(titulo: 'Lançar Estoque', onVoltar: _sair),
                Expanded(child: _corpo(estado)),
                _Rodape(estado: estado),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _corpo(LancarEstoqueState estado) {
    if (estado.carregandoProdutos) {
      return const EstadoCarregandoApp(mensagem: 'Carregando produtos...');
    }
    final erro = estado.erroProdutos;
    if (erro != null) {
      return EstadoErroApp(
        mensagem: erro,
        onTentarNovamente: _cubit.carregarProdutos,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        CampoDataApp(
          rotulo: 'Data da compra',
          obrigatorio: true,
          data: estado.dataCompra,
          ultimaData: DateTime.now(),
          erro: estado.erroData,
          onChanged: _cubit.alterarData,
        ),
        const SizedBox(height: 24),
        _TituloItens(quantidade: estado.itens.length),
        const SizedBox(height: 12),
        for (var i = 0; i < estado.itens.length; i++) ...[
          CartaoItemCompra(
            item: estado.itens[i],
            onTap: () => _abrirFolha(indice: i),
          ),
          const SizedBox(height: 12),
        ],
        BotaoApp.contorno(
          rotulo: estado.itens.isEmpty
              ? 'Adicionar produto'
              : 'Adicionar outro produto',
          onPressed: estado.produtos.isEmpty ? null : () => _abrirFolha(),
        ),
        const SizedBox(height: 12),
        _AtalhoCadastro(onTap: _cadastrarProduto),
      ],
    );
  }
}

class _TituloItens extends StatelessWidget {
  const _TituloItens({required this.quantidade});

  final int quantidade;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text('Produtos desta compra', style: estilos.titleMedium),
        ),
        Text(
          quantidade == 1 ? '1 item' : '$quantidade itens',
          style: estilos.bodyMedium?.copyWith(
            color: CoresApp.sobreSuperficieVariante,
          ),
        ),
      ],
    );
  }
}

class _AtalhoCadastro extends StatelessWidget {
  const _AtalhoCadastro({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Produto não aparece?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: onTap,
          child: const Text('Cadastrar novo produto'),
        ),
      ],
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({required this.estado});

  final LancarEstoqueState estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LancarEstoqueCubit>();
    final estilos = Theme.of(context).textTheme;
    final LancamentoEstoque lancamento = estado.lancamento;
    return SafeArea(
      top: false,
      minimum: EspacosApp.margemRodape,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Total de unidades')),
              Text('${lancamento.totalUnidades}', style: estilos.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Custo total da compra')),
              Text(
                FormatadorMoeda.formatar(lancamento.custoTotal),
                style: estilos.titleLarge?.copyWith(color: CoresApp.primaria),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BotaoApp(
            rotulo: estado.salvando ? 'Salvando...' : 'Salvar lançamento',
            onPressed: estado.podeSalvar ? cubit.salvar : null,
          ),
        ],
      ),
    );
  }
}
