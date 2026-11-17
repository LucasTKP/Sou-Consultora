// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/durabilidade.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/produtos/detalhes/produtos_detalhes_cubit.dart';
import 'package:sou_consultora/ui/modules/produtos/detalhes/produtos_detalhes_state.dart';
import 'package:sou_consultora/ui/modules/produtos/detalhes/widgets/aba_estoque.dart';
import 'package:sou_consultora/ui/modules/produtos/detalhes/widgets/linha_informacao.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/foto_quadrada_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';

/// Detalhes de um produto (aba Informações). A aba Estoque chega no change
/// `estoque`. Não existe exclusão de produto.
class ProdutosDetalhesScreen extends StatelessWidget {
  const ProdutosDetalhesScreen({super.key, required this.idProduto});

  final String idProduto;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProdutosDetalhesCubit(idProduto: idProduto),
      child: const _DetalhesVista(),
    );
  }
}

class _DetalhesVista extends StatelessWidget {
  const _DetalhesVista();

  void _aoAvisar(BuildContext context, ProdutosDetalhesState estado) {
    final aviso = estado.aviso;
    if (aviso == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(aviso), behavior: SnackBarBehavior.floating),
      );
    context.read<ProdutosDetalhesCubit>().limparAviso();
  }

  Future<void> _editar(BuildContext context, String id) async {
    final cubit = context.read<ProdutosDetalhesCubit>();
    final salvou = await context.push<bool>(RotasApp.editarProduto(id));
    if (salvou == true) await cubit.carregar();
  }

  Future<void> _lancarEstoque(BuildContext context, String id) async {
    final cubit = context.read<ProdutosDetalhesCubit>();
    final salvou = await context.push<bool>(
      RotasApp.lancarEstoque(produtoId: id),
    );
    if (salvou == true) await cubit.carregar();
  }

  Widget _rodape(BuildContext context, ProdutosDetalhesState estado) {
    final id = estado.produto!.id;
    final estoque = estado.aba == AbaProduto.estoque;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: estoque
          ? BotaoApp(
              rotulo: 'Lançar Estoque',
              iconeInicio: const Icon(Icons.add_box_outlined),
              onPressed: () => _lancarEstoque(context, id),
            )
          : BotaoApp(
              rotulo: 'Editar Produto',
              iconeInicio: const Icon(Icons.edit_outlined),
              onPressed: () => _editar(context, id),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProdutosDetalhesCubit, ProdutosDetalhesState>(
      listenWhen: (antes, depois) => antes.aviso != depois.aviso,
      listener: _aoAvisar,
      builder: (context, estado) {
        final produto = estado.produto;
        return Scaffold(
          body: Column(
            children: [
              const CabecalhoApp(titulo: 'Detalhes do Produto'),
              Expanded(child: _corpo(context, estado)),
              if (produto != null) _rodape(context, estado),
            ],
          ),
        );
      },
    );
  }

  Widget _corpo(BuildContext context, ProdutosDetalhesState estado) {
    final produto = estado.produto;
    if (produto != null) return _Conteudo(estado: estado, produto: produto);
    final erro = estado.erro;
    if (erro != null) {
      return EstadoErroApp(
        mensagem: erro,
        onTentarNovamente: context.read<ProdutosDetalhesCubit>().carregar,
      );
    }
    return const EstadoCarregandoApp();
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.estado, required this.produto});

  final ProdutosDetalhesState estado;
  final ResumoProduto produto;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        _Topo(produto: produto),
        const SizedBox(height: 16),
        _Abas(
          selecionada: estado.aba,
          qtdEstoque: produto.qtdDisponivel,
          onChanged: context.read<ProdutosDetalhesCubit>().alterarAba,
        ),
        const SizedBox(height: 8),
        ...switch (estado.aba) {
          AbaProduto.informacoes => _informacoes(),
          AbaProduto.estoque => AbaEstoque.itens(context, estado),
        },
      ],
    );
  }

  /// Linhas de informação; campos vazios ficam de fora.
  List<Widget> _informacoes() {
    final custo = produto.precoCusto;
    final durabilidade = produto.durabilidadeDias;
    final codigo = produto.codigo;
    final validade = produto.validadeAtual;
    final observacoes = produto.observacoes;
    return [
      LinhaInformacao(
        rotulo: 'Preço de venda',
        valor: FormatadorMoeda.formatar(produto.precoVenda),
        destaque: true,
      ),
      if (custo != null)
        LinhaInformacao(
          rotulo: 'Preço de custo',
          valor: FormatadorMoeda.formatar(custo),
        ),
      if (durabilidade != null)
        LinhaInformacao(
          rotulo: 'Durabilidade estimada',
          valor: Durabilidade.texto(durabilidade),
          dica: 'Ideal para prever recompra',
        ),
      LinhaInformacao(rotulo: 'Categoria', valor: produto.categoriaNome),
      if (codigo != null)
        LinhaInformacao(rotulo: 'Código / Ref.', valor: codigo),
      if (validade != null)
        LinhaInformacao(
          rotulo: 'Validade atual',
          valor: FormatadorData.curta(validade),
        ),
      if (observacoes != null)
        LinhaInformacao(
          rotulo: 'Observações',
          valor: observacoes,
          emBloco: true,
        ),
    ];
  }
}

class _Topo extends StatelessWidget {
  const _Topo({required this.produto});

  final ResumoProduto produto;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Row(
      children: [
        FotoQuadradaApp(url: produto.urlFoto, tamanho: TamanhoAvatar.destaque),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                produto.fornecedorNome.toUpperCase(),
                style: estilos.labelMedium?.copyWith(
                  color: CoresApp.sobreSuperficieVariante,
                ),
              ),
              Text(produto.nome, style: estilos.titleMedium),
              Text(
                FormatadorMoeda.formatar(produto.precoVenda),
                style: estilos.titleLarge?.copyWith(color: CoresApp.primaria),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Abas "Informações" e "Estoque N" (N = unidades disponíveis).
class _Abas extends StatelessWidget {
  const _Abas({
    required this.selecionada,
    required this.qtdEstoque,
    required this.onChanged,
  });

  final AbaProduto selecionada;
  final int qtdEstoque;
  final ValueChanged<AbaProduto> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _aba(
            context,
            AbaProduto.informacoes,
            Icons.info_outline_rounded,
            'Informações',
          ),
        ),
        Expanded(
          child: _aba(
            context,
            AbaProduto.estoque,
            Icons.inventory_2_outlined,
            'Estoque',
            contador: qtdEstoque,
          ),
        ),
      ],
    );
  }

  Widget _aba(
    BuildContext context,
    AbaProduto aba,
    IconData icone,
    String rotulo, {
    int? contador,
  }) {
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
                  contador == null ? rotulo : '$rotulo $contador',
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
