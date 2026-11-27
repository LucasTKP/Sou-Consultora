// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/widgets/avatares/foto_quadrada_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';

/// Card do produto na lista: foto, nome, preço de venda e estoque.
class CartaoProduto extends StatelessWidget {
  const CartaoProduto({super.key, required this.produto, required this.onTap});

  final ResumoProduto produto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodySmall;
    return CartaoListaApp(
      titulo: produto.nome,
      // O nome ganha a largura toda (até 2 linhas); valor e selo do estoque
      // dividem a linha de baixo e quebram juntos se a fonte for grande.
      maxLinhasTitulo: 2,
      linhaInferior: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(FormatadorMoeda.formatar(produto.precoVenda), style: estilo),
          SeloStatusApp(
            rotulo: produto.textoEstoque,
            status: statusDoEstoque(produto.situacao),
          ),
        ],
      ),
      inicio: FotoQuadradaApp(url: produto.urlFoto),
      onTap: onTap,
    );
  }

  /// Verde com estoque, amarelo com pouco e vermelho esgotado.
  static StatusSelo statusDoEstoque(SituacaoEstoque situacao) =>
      switch (situacao) {
        SituacaoEstoque.esgotado => StatusSelo.perigo,
        SituacaoEstoque.baixo => StatusSelo.alerta,
        SituacaoEstoque.emEstoque => StatusSelo.sucesso,
      };
}
