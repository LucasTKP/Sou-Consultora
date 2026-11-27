// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/resumo_servico.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/servicos/widgets/icone_servico.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';
import 'package:sou_consultora/ui/widgets/cards/linha_situacao_app.dart';

/// Card do serviço: foto ou ícone e nome; embaixo, a categoria em cor e o preço.
class CartaoServico extends StatelessWidget {
  const CartaoServico({super.key, required this.servico, required this.onTap});

  final ResumoServico servico;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CartaoListaApp(
      titulo: servico.nome,
      linhaInferior: LinhaSituacaoApp(
        status: servico.categoriaNome,
        cor: StatusSelo.primario.corTexto,
        detalhes: [FormatadorMoeda.formatar(servico.precoCobrado)],
      ),
      inicio: IconeServico(
        categoria: servico.categoriaNome,
        urlFoto: servico.urlFoto,
      ),
      onTap: onTap,
    );
  }
}
