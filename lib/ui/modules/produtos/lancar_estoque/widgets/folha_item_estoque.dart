// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/item_lancamento.dart';
import 'package:sou_consultora/core/model/margem.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_data_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/seletor_quantidade_app.dart';

/// O que a folha devolveu: o item (novo ou alterado) ou o pedido de remover.
sealed class EscolhaItem {
  const EscolhaItem();
}

final class ItemConfirmado extends EscolhaItem {
  const ItemConfirmado(this.item);

  final ItemLancamento item;
}

final class ItemRemovido extends EscolhaItem {
  const ItemRemovido();
}

/// Folha "Adicionar Produto ao Estoque": produto, quantidade, custo,
/// validade do lote e margem prevista.
abstract final class FolhaItemEstoque {
  static Future<EscolhaItem?> mostrar(
    BuildContext context, {
    required List<ResumoProduto> produtos,
    required DateTime dataCompra,
    required bool Function(String produtoId) jaNaCompra,
    ItemLancamento? item,
    ResumoProduto? produtoInicial,
  }) {
    return FolhaInferiorApp.mostrar<EscolhaItem>(
      context: context,
      titulo: item == null ? 'Adicionar Produto ao Estoque' : 'Alterar item',
      subtitulo: 'Selecione o produto e defina custo e quantidade',
      conteudo: (_) => _ConteudoFolha(
        produtos: produtos,
        dataCompra: dataCompra,
        jaNaCompra: jaNaCompra,
        item: item,
        produtoInicial: produtoInicial,
      ),
    );
  }
}

class _ConteudoFolha extends StatefulWidget {
  const _ConteudoFolha({
    required this.produtos,
    required this.dataCompra,
    required this.jaNaCompra,
    this.item,
    this.produtoInicial,
  });

  final List<ResumoProduto> produtos;
  final DateTime dataCompra;
  final bool Function(String produtoId) jaNaCompra;
  final ItemLancamento? item;
  final ResumoProduto? produtoInicial;

  @override
  State<_ConteudoFolha> createState() => _ConteudoFolhaState();
}

class _ConteudoFolhaState extends State<_ConteudoFolha> {
  late ResumoProduto? _produto = widget.item?.produto ?? widget.produtoInicial;
  late int _quantidade = widget.item?.quantidade ?? 1;
  late int _custo = widget.item?.custoUnitario ?? 0;
  late DateTime? _validade = widget.item?.validade;
  String? _erroProduto;
  String? _erroCusto;
  String? _erroValidade;

  bool get _editando => widget.item != null;

  void _confirmar() {
    final produto = _produto;
    var erroProduto = ItemLancamento.validarProduto(produto);
    final mesmoProduto = produto?.id == widget.item?.produto.id;
    if (produto != null && !mesmoProduto && widget.jaNaCompra(produto.id)) {
      erroProduto = LancamentoEstoque.mensagemRepetido;
    }
    setState(() {
      _erroProduto = erroProduto;
      _erroCusto = ItemLancamento.validarCusto(_custo);
      _erroValidade = ItemLancamento.validarValidade(
        _validade,
        widget.dataCompra,
      );
    });
    if (_erroProduto != null || _erroCusto != null || _erroValidade != null) {
      return;
    }
    Navigator.of(context).pop(
      ItemConfirmado(
        ItemLancamento(
          produto: produto!,
          quantidade: _quantidade,
          custoUnitario: _custo,
          validade: _validade,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final produto = _produto;
    // A folha já rola e respeita o teclado.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoSelecaoApp<ResumoProduto>(
          rotulo: 'Selecionar Produto',
          obrigatorio: true,
          placeholder: 'Escolha o produto',
          opcoes: widget.produtos,
          rotuloDe: (p) => p.nome,
          valor: produto,
          buscavel: true,
          erro: _erroProduto,
          icone: Icons.inventory_2_outlined,
          onChanged: (p) => setState(() {
            _produto = p;
            _erroProduto = null;
          }),
        ),
        if (produto != null) ...[
          const SizedBox(height: 12),
          _InfoProduto(produto: produto),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quantidade *',
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
                rotulo: 'Custo unitário',
                obrigatorio: true,
                centavosIniciais: _custo,
                erro: _erroCusto,
                onChanged: (c) => setState(() {
                  _custo = c;
                  _erroCusto = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CampoDataApp(
          rotulo: 'Validade do lote',
          opcional: true,
          data: _validade,
          primeiraData: widget.dataCompra,
          ultimaData: DateTime(widget.dataCompra.year + 10),
          erro: _erroValidade,
          onChanged: (d) => setState(() {
            _validade = d;
            _erroValidade = null;
          }),
        ),
        if (produto != null && _custo > 0) ...[
          const SizedBox(height: 16),
          _CartaoMargem(
            margem: Margem.calcular(
              precoVenda: produto.precoVenda,
              custo: _custo,
            ),
          ),
        ],
        const SizedBox(height: 24),
        BotaoApp(
          rotulo: _editando ? 'Salvar item' : 'Adicionar à Compra',
          iconeInicio: const Icon(Icons.check_circle_outline_rounded),
          onPressed: _confirmar,
        ),
        const SizedBox(height: 12),
        if (_editando)
          BotaoApp.secundario(
            rotulo: 'Remover da compra',
            iconeInicio: const Icon(Icons.delete_outline_rounded),
            onPressed: () => Navigator.of(context).pop(const ItemRemovido()),
          )
        else
          BotaoApp.secundario(
            rotulo: 'Voltar sem adicionar',
            iconeInicio: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }
}

class _InfoProduto extends StatelessWidget {
  const _InfoProduto({required this.produto});

  final ResumoProduto produto;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final rotulo = estilos.labelSmall?.copyWith(
      color: CoresApp.sobreSuperficieVariante,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CoresApp.primariaSuave.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PREÇO DE VENDA', style: rotulo),
                  Text(
                    FormatadorMoeda.formatar(produto.precoVenda),
                    style: estilos.titleSmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('ESTOQUE ATUAL', style: rotulo),
                Text('${produto.qtdDisponivel} un', style: estilos.titleSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoMargem extends StatelessWidget {
  const _CartaoMargem({required this.margem});

  final Margem margem;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final porcentagem = margem.porcentagem
        .toStringAsFixed(1)
        .replaceAll('.', ',');
    final status = switch (margem.faixa) {
      FaixaMargem.excelente => StatusSelo.sucesso,
      FaixaMargem.boa => StatusSelo.primario,
      FaixaMargem.baixa => StatusSelo.alerta,
      FaixaMargem.prejuizo => StatusSelo.perigo,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CoresApp.sucessoContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MARGEM PREVISTA',
                    style: estilos.labelSmall?.copyWith(
                      color: CoresApp.sucesso,
                    ),
                  ),
                  Text(
                    '${FormatadorMoeda.formatar(margem.valor)} ($porcentagem%)',
                    style: estilos.titleSmall,
                  ),
                ],
              ),
            ),
            SeloStatusApp(rotulo: margem.faixa.rotulo, status: status),
          ],
        ),
      ),
    );
  }
}
