// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/item_venda.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/core/model/resumo_servico.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/formatadores/formatador_percentual.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/alternador_segmentado_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_percentual_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/interruptor_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/seletor_quantidade_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';

/// Folha "Adicionar Item à Venda": produto ou serviço do catálogo, quantidade,
/// desconto e, para produto, se baixa do estoque. Devolve o item ou null.
abstract final class FolhaItemVenda {
  static Future<ItemPedido?> mostrar(
    BuildContext context, {
    required List<ResumoProduto> Function() produtos,
    required List<ResumoServico> Function() servicos,
    required bool Function(String chave) jaNoPedido,
    required Future<void> Function() onNovoProduto,
    required Future<void> Function() onNovoServico,
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
        onNovoProduto: onNovoProduto,
        onNovoServico: onNovoServico,
        item: item,
      ),
    );
  }
}

/// Como o desconto é digitado.
enum _ModoDesconto { valor, percentual }

class _ConteudoFolha extends StatefulWidget {
  const _ConteudoFolha({
    required this.produtos,
    required this.servicos,
    required this.jaNoPedido,
    required this.onNovoProduto,
    required this.onNovoServico,
    this.item,
  });

  final List<ResumoProduto> Function() produtos;
  final List<ResumoServico> Function() servicos;
  final bool Function(String chave) jaNoPedido;
  final Future<void> Function() onNovoProduto;
  final Future<void> Function() onNovoServico;
  final ItemPedido? item;

  @override
  State<_ConteudoFolha> createState() => _ConteudoFolhaState();
}

class _ConteudoFolhaState extends State<_ConteudoFolha> {
  late TipoItem _tipo = widget.item?.tipo ?? TipoItem.produto;
  late ResumoProduto? _produto = _produtoInicial();
  late ResumoServico? _servico = _servicoInicial();
  late int _quantidade = widget.item?.quantidade ?? 1;
  late _ModoDesconto _modo = widget.item?.percentualDesconto == null
      ? _ModoDesconto.valor
      : _ModoDesconto.percentual;
  late int _desconto = widget.item?.desconto ?? 0;
  late int _percentual = widget.item?.percentualDesconto ?? 0;
  late bool _baixar = widget.item?.baixarEstoque ?? true;
  String? _erroItem;
  String? _erroDesconto;

  ResumoProduto? _produtoInicial() {
    final item = widget.item;
    if (item == null || item.tipo != TipoItem.produto) return null;
    return widget.produtos().where((p) => p.id == item.catalogoId).firstOrNull;
  }

  ResumoServico? _servicoInicial() {
    final item = widget.item;
    if (item == null || item.tipo != TipoItem.servico) return null;
    return widget.servicos().where((s) => s.id == item.catalogoId).firstOrNull;
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
        desconto: _descontoSobre(produto.precoVenda),
        percentualDesconto: _percentualDigitado,
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
      desconto: _descontoSobre(servico.precoCobrado),
      percentualDesconto: _percentualDigitado,
      baixarEstoque: false,
      urlFoto: servico.urlFoto,
      categoriaServico: servico.categoriaNome,
    );
  }

  int? get _percentualDigitado =>
      _modo == _ModoDesconto.percentual && _percentual > 0 ? _percentual : null;

  /// Em %, acompanha a quantidade e o item escolhido.
  int _descontoSobre(int precoUnitario) {
    if (_modo == _ModoDesconto.valor) return _desconto;
    return ItemPedido.descontoPorPercentual(
      percentual: _percentual,
      bruto: precoUnitario * _quantidade,
    );
  }

  String? _validarDesconto(ItemPedido item) {
    final percentual = item.percentualDesconto;
    if (percentual != null) return ItemPedido.validarPercentual(percentual);
    return ItemPedido.validarDesconto(
      desconto: item.desconto,
      bruto: item.bruto,
    );
  }

  /// Trocar o modo zera o desconto: "10" em R$ não é "10" em %.
  void _trocarModo(_ModoDesconto modo) {
    if (modo == _modo) return;
    setState(() {
      _modo = modo;
      _desconto = 0;
      _percentual = 0;
      _erroDesconto = null;
    });
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

  /// Abre o cadastro e, na volta, relê a lista para o item novo aparecer.
  Future<void> _cadastrarProduto() async {
    await widget.onNovoProduto();
    if (mounted) setState(() {});
  }

  Future<void> _cadastrarServico() async {
    await widget.onNovoServico();
    if (mounted) setState(() {});
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
      _erroDesconto = item == null ? null : _validarDesconto(item);
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

  Widget _campoDesconto() {
    if (_modo == _ModoDesconto.percentual) {
      return CampoPercentualApp(
        rotulo: 'Desconto',
        opcional: true,
        centesimosIniciais: _percentual,
        erro: _erroDesconto,
        onChanged: (p) => setState(() {
          _percentual = p;
          _erroDesconto = null;
        }),
      );
    }
    return CampoMoedaApp(
      rotulo: 'Desconto',
      opcional: true,
      centavosIniciais: _desconto,
      erro: _erroDesconto,
      onChanged: (c) => setState(() {
        _desconto = c;
        _erroDesconto = null;
      }),
    );
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
            opcoes: widget.produtos(),
            rotuloDe: (p) => p.nome,
            valor: _produto,
            buscavel: true,
            erro: _erroItem,
            icone: Icons.search_rounded,
            onChanged: (p) => setState(() {
              _produto = p;
              _erroItem = null;
            }),
            onCadastrar: _cadastrarProduto,
            rotuloCadastrar: 'Cadastrar produto',
          )
        else
          CampoSelecaoApp<ResumoServico>(
            rotulo: 'Selecionar Serviço',
            placeholder: 'Escolha o serviço',
            opcoes: widget.servicos(),
            rotuloDe: (s) => s.nome,
            valor: _servico,
            buscavel: true,
            erro: _erroItem,
            icone: Icons.search_rounded,
            onChanged: (s) => setState(() {
              _servico = s;
              _erroItem = null;
            }),
            onCadastrar: _cadastrarServico,
            rotuloCadastrar: 'Cadastrar serviço',
          ),
        const SizedBox(height: 16),
        SeletorQuantidadeApp(
          valor: _quantidade,
          onChanged: (q) => setState(() => _quantidade = q),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _campoDesconto()),
            const SizedBox(width: 12),
            SizedBox(
              width: 132,
              child: AlternadorSegmentadoApp<_ModoDesconto>(
                opcoes: const [
                  OpcaoSegmento(valor: _ModoDesconto.valor, rotulo: r'R$'),
                  OpcaoSegmento(valor: _ModoDesconto.percentual, rotulo: '%'),
                ],
                selecionado: _modo,
                onChanged: _trocarModo,
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
        // Desconto inválido daria um resumo com valores negativos.
        if (item != null && _validarDesconto(item) == null) ...[
          const SizedBox(height: 16),
          _Resumo(item: item),
        ],
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
              item.percentualDesconto == null
                  ? 'Desconto aplicado:'
                  : 'Desconto aplicado '
                        '(${FormatadorPercentual.formatar(item.percentualDesconto!)}%):',
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
