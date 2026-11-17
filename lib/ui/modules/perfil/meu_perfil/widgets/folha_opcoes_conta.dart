// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';

enum AcaoConta { sair, apagar }

/// Folha "Opções da Conta": sair e apagar conta.
abstract final class FolhaOpcoesConta {
  static Future<AcaoConta?> mostrar(BuildContext context) {
    return FolhaInferiorApp.mostrar<AcaoConta>(
      context: context,
      titulo: 'Opções da Conta',
      conteudo: (contexto) => Column(
        children: [
          CartaoListaApp(
            titulo: 'Sair da Conta',
            subtitulo: 'Desconectar deste dispositivo',
            inicio: _icone(
              Icons.logout_rounded,
              CoresApp.primariaSuave,
              CoresApp.primariaEscura,
            ),
            onTap: () => Navigator.of(contexto).pop(AcaoConta.sair),
          ),
          const SizedBox(height: 12),
          CartaoListaApp(
            titulo: 'Apagar Conta',
            subtitulo: 'Excluir permanentemente meus dados',
            inicio: _icone(
              Icons.delete_forever_outlined,
              CoresApp.perigoContainer,
              CoresApp.perigo,
            ),
            onTap: () => Navigator.of(contexto).pop(AcaoConta.apagar),
          ),
        ],
      ),
    );
  }

  static Widget _icone(IconData icone, Color fundo, Color cor) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icone, color: cor),
    );
  }
}
