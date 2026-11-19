// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/filtro_produtos.dart';
import 'package:sou_consultora/ui/modules/produtos/lista/produtos_lista_cubit.dart';
import 'package:sou_consultora/ui/modules/produtos/lista/produtos_lista_state.dart';
import 'package:sou_consultora/ui/modules/produtos/lista/widgets/cartao_produto.dart';
import 'package:sou_consultora/ui/navegacao/casca/casca_principal_screen.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_ordenacao_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_flutuante_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/texto_contagem_lista.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_busca_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';

enum _AcaoProduto { novo, estoque }

/// Tela principal de Produtos (item da barra inferior).
class ProdutosListaScreen extends StatelessWidget {
  const ProdutosListaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProdutosListaCubit(),
      child: const _ProdutosListaVista(),
    );
  }
}

class _ProdutosListaVista extends StatelessWidget {
  const _ProdutosListaVista();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CabecalhoApp(
          titulo: 'Produtos',
          acao: AcaoCabecalho.menu,
          onMenu: () => CascaPrincipalScreen.abrirMenu(context),
        ),
        Expanded(
          child: Stack(
            children: [
              BlocBuilder<ProdutosListaCubit, ProdutosListaState>(
                builder: _corpo,
              ),
              BlocBuilder<ProdutosListaCubit, ProdutosListaState>(
                builder: (context, estado) {
                  final vazio =
                      estado.carregamento == CarregamentoProdutos.pronto &&
                      estado.todos.isEmpty;
                  if (vazio) return const SizedBox.shrink();
                  return Positioned(
                    right: 16,
                    // A casca usa `extendBody`: a altura da barra inferior chega
                    // aqui como padding.
                    bottom: MediaQuery.paddingOf(context).bottom + 16,
                    child: BotaoFlutuanteApp(
                      rotulo: 'Opções',
                      icone: Icons.more_horiz_rounded,
                      onPressed: () => _abrirOpcoes(context),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _abrirOpcoes(BuildContext context) async {
    final acao = await FolhaInferiorApp.mostrar<_AcaoProduto>(
      context: context,
      titulo: 'Opções',
      conteudo: (contexto) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BotaoApp(
            rotulo: 'Novo produto',
            onPressed: () => Navigator.of(contexto).pop(_AcaoProduto.novo),
          ),
          const SizedBox(height: 12),
          BotaoApp.contorno(
            rotulo: 'Lançar estoque',
            onPressed: () => Navigator.of(contexto).pop(_AcaoProduto.estoque),
          ),
        ],
      ),
    );
    if (!context.mounted || acao == null) return;
    switch (acao) {
      case _AcaoProduto.novo:
        context.push(RotasApp.novoProduto);
      case _AcaoProduto.estoque:
        context.push(RotasApp.lancarEstoque());
    }
  }

  Widget _corpo(BuildContext context, ProdutosListaState estado) {
    return switch (estado.carregamento) {
      CarregamentoProdutos.carregando => const EstadoCarregandoApp(
        mensagem: 'Carregando produtos...',
      ),
      CarregamentoProdutos.erro => EstadoErroApp(
        mensagem:
            estado.mensagemErro ?? 'Não foi possível carregar os produtos.',
        onTentarNovamente: context.read<ProdutosListaCubit>().carregar,
      ),
      CarregamentoProdutos.pronto when estado.todos.isEmpty =>
        const _ListaVazia(),
      CarregamentoProdutos.pronto => _Lista(estado: estado),
    };
  }
}

class _ListaVazia extends StatelessWidget {
  const _ListaVazia();

  @override
  Widget build(BuildContext context) {
    return EstadoVazioApp(
      titulo: 'Nenhum produto ainda',
      mensagem: 'Cadastre o que você vende para registrar vendas e estoque.',
      icone: Icons.inventory_2_outlined,
      acao: BotaoApp(
        rotulo: 'Cadastrar produto',
        expande: false,
        onPressed: () => context.push(RotasApp.novoProduto),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.estado});

  final ProdutosListaState estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProdutosListaCubit>();
    final visiveis = estado.visiveis;
    return RefreshIndicator(
      onRefresh: cubit.carregar,
      child: ListView(
        // Espaço no fim para a barra inferior e o botão flutuante não
        // cobrirem o último card.
        padding: EdgeInsets.fromLTRB(
          16,
          24,
          16,
          MediaQuery.paddingOf(context).bottom + 160,
        ),
        children: [
          CampoBuscaApp(
            rotulo: 'Buscar',
            placeholder: 'Buscar por nome, marca ou código...',
            onChanged: cubit.alterarBusca,
          ),
          const SizedBox(height: 20),
          _Filtros(estado: estado),
          const SizedBox(height: 16),
          _Resumo(
            total: estado.todos.length,
            ordem: estado.ordem,
            onChanged: cubit.alterarOrdem,
          ),
          const SizedBox(height: 8),
          if (visiveis.isEmpty) const _SemResultado(),
          for (final produto in visiveis) ...[
            CartaoProduto(
              produto: produto,
              onTap: () => context.push(RotasApp.detalhesProduto(produto.id)),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.estado});

  final ProdutosListaState estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProdutosListaCubit>();
    final contagens = estado.contagens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CampoSelecaoApp<FiltroMarcaCategoria>(
            rotulo: 'Marca / Categoria',
            opcoes: estado.opcoesMarcaCategoria,
            rotuloDe: (opcao) => opcao.rotulo,
            valor: estado.marcaCategoria,
            buscavel: true,
            onChanged: cubit.alterarMarcaCategoria,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CampoSelecaoApp<StatusFiltroEstoque>(
            rotulo: 'Estoque',
            opcoes: StatusFiltroEstoque.values,
            rotuloDe: (status) => '${status.rotulo} (${contagens[status]})',
            valor: estado.estoque,
            onChanged: cubit.alterarEstoque,
          ),
        ),
      ],
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({
    required this.total,
    required this.ordem,
    required this.onChanged,
  });

  final int total;
  final OrdemPreco ordem;
  final ValueChanged<OrdemPreco> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextoContagemLista(
            total: total,
            singular: 'produto',
            plural: 'produtos',
          ),
        ),
        BotaoOrdenacaoApp<OrdemPreco>(
          opcoes: OrdemPreco.values,
          rotuloDe: (item) => item.rotulo,
          valor: ordem,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SemResultado extends StatelessWidget {
  const _SemResultado();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        'Nenhum produto encontrado',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: CoresApp.sobreSuperficieVariante),
      ),
    );
  }
}
