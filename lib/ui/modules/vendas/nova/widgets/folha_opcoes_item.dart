// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';

/// O que foi escolhido na folha de opções do item.
enum OpcaoItem { editar, excluir }

/// Folha aberta pelo lápis de um item do pedido: editar ou excluir.
abstract final class FolhaOpcoesItem {
  static Future<OpcaoItem?> mostrar(BuildContext context, String nome) {
    return FolhaInferiorApp.mostrar<OpcaoItem>(
      context: context,
      titulo: nome,
      conteudo: (contexto) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _opcao(
            contexto,
            OpcaoItem.editar,
            Icons.edit_outlined,
            'Editar',
            'Quantidade e desconto',
            CoresApp.primariaSuave,
            CoresApp.primaria,
          ),
          const SizedBox(height: 12),
          _opcao(
            contexto,
            OpcaoItem.excluir,
            Icons.delete_outline_rounded,
            'Excluir',
            'Tira este item do pedido',
            CoresApp.perigoContainer,
            CoresApp.perigo,
          ),
        ],
      ),
    );
  }

  static Widget _opcao(
    BuildContext contexto,
    OpcaoItem opcao,
    IconData icone,
    String titulo,
    String descricao,
    Color fundo,
    Color cor,
  ) {
    return CartaoListaApp(
      titulo: titulo,
      subtitulo: descricao,
      inicio: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icone, color: cor),
      ),
      onTap: () => Navigator.of(contexto).pop(opcao),
    );
  }
}
