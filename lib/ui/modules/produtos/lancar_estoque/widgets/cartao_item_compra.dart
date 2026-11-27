import 'package:flutter/widgets.dart';
import 'package:sou_consultora/core/model/item_lancamento.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/foto_quadrada_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';

/// Um produto da compra: foto, nome e "3 un • R$ 465,00". Tocar reabre a folha.
class CartaoItemCompra extends StatelessWidget {
  const CartaoItemCompra({super.key, required this.item, required this.onTap});

  final ItemLancamento item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CartaoListaApp(
      titulo: item.produto.nome,
      subtitulo:
          '${item.quantidade} un • ${FormatadorMoeda.formatar(item.total)}',
      inicio: FotoQuadradaApp(
        url: item.produto.urlFoto,
        tamanho: TamanhoAvatar.miniatura,
      ),
      onTap: onTap,
    );
  }
}
