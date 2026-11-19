// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/item_venda.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/core/model/resumo_servico.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/alternador_segmentado_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/interruptor_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/seletor_quantidade_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';

/// Folha "Adicionar Item à Venda": produto ou serviço do catálogo, quantidade,
/// desconto e, para produto, se baixa do estoque. Devolve o item ou null.
abstract final class FolhaItemVenda {
  static Future<ItemPedido?> mostrar(
    BuildContext context, {
    required List<ResumoProduto> produtos,
    required List<ResumoServico> servicos,
    required bool Function(String chave) jaNoPedido,
    ItemPedido? item,
  }) {
    return FolhaInferiorApp.mostrar<ItemPedido>(
      context: context,
      titulo: item == null ? 'Adicionar Item à Venda' : 'Alterar Item',
      subtitulo: 'Selecione o produto ou serviço do catálogo',
      conteudo: (_) => _ConteudoFolha(
        produtos: produtos,
        servicos: servicos,
        jaNoPedido: jaNoPedido,
        item: item,
      ),
    );
  }
}

class _ConteudoFolha extends StatefulWidget {
  const _ConteudoFolha({
    required this.produtos,
    required this.servicos,
    required this.jaNoPedido,
    this.item,
  });

  final List<ResumoProduto> produtos;
  final List<ResumoServico> servicos;
  final bool Function(String chave) jaNoPedido;
  final ItemPedido? item;

  @override
  State<_ConteudoFolha> createState() => _ConteudoFolhaState();
}

class _ConteudoFolhaState extends State<_ConteudoFolha> {
  late TipoItem _tipo = widget.item?.tipo ?? TipoItem.produto;
  late ResumoProduto? _produto = _produtoInicial();
  late ResumoServico? _servico = _servicoInicial();
  late int _quantidade = widget.item?.quantidade ?? 1;
  late int _desconto = widget.item?.desconto ?? 0;
  late bool _baixar = widget.item?.baixarEstoque ?? true;
  String? _erroItem;
  String? _erroDesconto;

  ResumoProduto? _produtoInicial() {
    final item = widget.item;
    if (item == null || item.tipo != TipoItem.produto) return null;
    return widget.produtos.where((p) => p.id == item.catalogoId).firstOrNull;
  }

  ResumoServico? _servicoInicial() {
    final item = widget.item;
    if (item == null || item.tipo != TipoItem.servico) return null;
    return widget.servicos.where((s) => s.id == item.catalogoId).firstOrNull;
  }

  /// Item montado com o que está na folha (null sem produto/serviço escolhido).
  ItemPedido? get _item {
    if (_tipo == TipoItem.produto) {
      final produto = _produto;
      if (produto == null) return null;
      return ItemPedido(
        tipo: TipoItem.produto,
        catalogoId: produto.id,
        nome: produto.nome,
        precoUnitario: produto.precoVenda,
        quantidade: _quantidade,
        desconto: _desconto,
        baixarEstoque: _baixar,
        saldoEstoque: _saldo(produto),
        urlFoto: produto.urlFoto,
      );
    }
    final servico = _servico;
    if (servico == null) return null;
    return ItemPedido(
      tipo: TipoItem.servico,
      catalogoId: servico.id,
      nome: servico.nome,
      precoUnitario: servico.precoCobrado,
      quantidade: _quantidade,
      desconto: _desconto,
      baixarEstoque: false,
      urlFoto: servico.urlFoto,
      categoriaServico: servico.categoriaNome,
    );
  }

  /// Na edição, o que este item já baixou volta ao saldo antes de regravar.
  int _saldo(ResumoProduto produto) {
    final item = widget.item;
    if (item != null && item.catalogoId == produto.id) {
      return item.saldoEstoque ?? produto.qtdDisponivel;
    }
    return produto.qtdDisponivel;
  }

  String? get _erroQuantidade {
    final item = _item;
    if (item == null) return null;
    return ItemPedido.validarQuantidade(
      quantidade: _quantidade,
      baixa: item.baixa,
      saldo: item.saldoEstoque,
    );
  }

  void _salvar() {
    final item = _item;
    final mesmo = item?.chave == widget.item?.chave;
    setState(() {
      _erroItem = item == null
          ? (_tipo == TipoItem.produto
                ? 'Escolha o produto'
                : 'Escolha o serviço')
          : (!mesmo && widget.jaNoPedido(item.chave))
          ? 'Este item já está no pedido'
          : null;
      _erroDesconto = item == null
          ? null
          : ItemPedido.validarDesconto(desconto: _desconto, bruto: item.bruto);
    });
    final erroQuantidade = _erroQuantidade;
    if (erroQuantidade != null && _erroItem == null && _erroDesconto == null) {
      // O erro de unidades só aparece ao tocar em Salvar.
      ToastApp.erro(context, erroQuantidade);
      return;
    }
    if (_erroItem != null || _erroDesconto != null || erroQuantidade != null) {
      return;
    }
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AlternadorSegmentadoApp<TipoItem>(
          opcoes: const [
            OpcaoSegmento(
              valor: TipoItem.produto,
              rotulo: 'Produto',
              icone: Icons.inventory_2_outlined,
            ),
            OpcaoSegmento(
              valor: TipoItem.servico,
              rotulo: 'Serviço',
              icone: Icons.spa_outlined,
            ),
          ],
          selecionado: _tipo,
          onChanged: (tipo) => setState(() {
            _tipo = tipo;
            _erroItem = null;
          }),
        ),
        const SizedBox(height: 16),
        if (_tipo == TipoItem.produto)
          CampoSelecaoApp<ResumoProduto>(
            rotulo: 'Selecionar Produto',
            placeholder: 'Escolha o produto',
            opcoes: widget.produtos,
            rotuloDe: (p) => p.nome,
            valor: _produto,
            buscavel: true,
            erro: _erroItem,
            icone: Icons.search_rounded,
            onChanged: (p) => setState(() {
              _produto = p;
              _erroItem = null;
            }),
          )
        else
          CampoSelecaoApp<ResumoServico>(
            rotulo: 'Selecionar Serviço',
            placeholder: 'Escolha o serviço',
            opcoes: widget.servicos,
            rotuloDe: (s) => s.nome,
            valor: _servico,
            buscavel: true,
            erro: _erroItem,
            icone: Icons.search_rounded,
            onChanged: (s) => setState(() {
              _servico = s;
              _erroItem = null;
            }),
          ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quantidade',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  SeletorQuantidadeApp(
                    valor: _quantidade,
                    onChanged: (q) => setState(() => _quantidade = q),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CampoMoedaApp(
                rotulo: 'Desconto',
                opcional: true,
                centavosIniciais: _desconto,
                erro: _erroDesconto,
                onChanged: (c) => setState(() {
                  _desconto = c;
                  _erroDesconto = null;
                }),
              ),
            ),
          ],
        ),
        if (_tipo == TipoItem.produto && item != null) ...[
          const SizedBox(height: 16),
          InterruptorApp(
            rotulo: 'Baixar do estoque',
            descricao: '${item.saldoEstoque ?? 0} un disponíveis.',
            valor: _baixar,
            onChanged: (valor) => setState(() => _baixar = valor),
          ),
        ],
        if (item != null) ...[const SizedBox(height: 16), _Resumo(item: item)],
        const SizedBox(height: 24),
        BotaoApp(rotulo: 'Salvar', onPressed: _salvar),
      ],
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.item});

  final ItemPedido item;

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
              'Valor unitário:',
              FormatadorMoeda.formatar(item.precoUnitario),
              estilos.bodyMedium,
            ),
            const SizedBox(height: 4),
            _linha(
              'Desconto aplicado:',
              '- ${FormatadorMoeda.formatar(item.desconto)}',
              estilos.bodyMedium?.copyWith(color: CoresApp.primaria),
            ),
            const Divider(color: CoresApp.primariaSuave),
            _linha(
              'Subtotal com desconto:',
              FormatadorMoeda.formatar(item.subtotal),
              estilos.titleMedium?.copyWith(color: CoresApp.primaria),
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
