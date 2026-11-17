// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/saida_produto.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';

/// Uma venda que consumiu o produto: cliente, data, unidades e valor.
class CartaoSaida extends StatelessWidget {
  const CartaoSaida({super.key, required this.saida});

  final SaidaProduto saida;

  @override
  Widget build(BuildContext context) {
    return CartaoListaApp(
      titulo: saida.clienteNome,
      subtitulo:
          '${FormatadorData.curta(saida.dataVenda)} • '
          '${FormatadorMoeda.formatar(saida.valor)}',
      inicio: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: CoresApp.primariaSuave,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.person_outline_rounded,
          color: CoresApp.primaria,
        ),
      ),
      selo: SeloStatusApp(
        rotulo: '- ${saida.quantidade} un',
        status: StatusSelo.perigo,
      ),
    );
  }
}
