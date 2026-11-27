// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';

/// Escolha feita na folha de foto.
enum AcaoFoto { camera, galeria, remover }

/// Folha de foto (perfil, produto): tirar, escolher da galeria ou remover.
abstract final class FolhaFotoApp {
  static Future<AcaoFoto?> mostrar(
    BuildContext context, {
    required String titulo,
    required bool temFoto,
    String descricaoRemover = 'Voltar a exibir as iniciais',
  }) {
    return FolhaInferiorApp.mostrar<AcaoFoto>(
      context: context,
      titulo: titulo,
      conteudo: (contexto) => Column(
        children: [
          _opcao(
            contexto,
            AcaoFoto.camera,
            Icons.photo_camera_outlined,
            'Tirar foto',
            'Usar a câmera do celular',
            CoresApp.primariaSuave,
            CoresApp.primaria,
          ),
          const SizedBox(height: 12),
          _opcao(
            contexto,
            AcaoFoto.galeria,
            Icons.photo_library_outlined,
            'Escolher da galeria',
            'JPG ou PNG, será recortada em 1:1',
            CoresApp.alertaContainer,
            CoresApp.alerta,
          ),
          if (temFoto) ...[
            const SizedBox(height: 12),
            _opcao(
              contexto,
              AcaoFoto.remover,
              Icons.delete_outline_rounded,
              'Remover foto',
              descricaoRemover,
              CoresApp.perigoContainer,
              CoresApp.perigo,
            ),
          ],
        ],
      ),
    );
  }

  static Widget _opcao(
    BuildContext contexto,
    AcaoFoto acao,
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
      onTap: () => Navigator.of(contexto).pop(acao),
    );
  }
}
