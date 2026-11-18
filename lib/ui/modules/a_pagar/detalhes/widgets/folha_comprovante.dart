// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/arquivo_comprovante.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';

/// Ver o comprovante atual ou anexar outro.
sealed class AcaoComprovante {
  const AcaoComprovante();
}

final class VerComprovante extends AcaoComprovante {
  const VerComprovante();
}

final class AnexarComprovante extends AcaoComprovante {
  const AnexarComprovante(this.origem);

  final OrigemComprovante origem;
}

/// Folha "Comprovante": ver (quando há) e anexar por câmera, galeria ou PDF.
abstract final class FolhaComprovante {
  static Future<AcaoComprovante?> mostrar(
    BuildContext context, {
    required bool temComprovante,
  }) {
    return FolhaInferiorApp.mostrar<AcaoComprovante>(
      context: context,
      titulo: 'Comprovante',
      subtitulo: temComprovante
          ? 'Anexar outro substitui o atual.'
          : 'Foto ou PDF de até 10 MB.',
      conteudo: (contexto) => Column(
        children: [
          if (temComprovante) ...[
            _opcao(
              contexto,
              const VerComprovante(),
              Icons.visibility_outlined,
              'Ver comprovante',
              'Abre o arquivo anexado',
            ),
            const SizedBox(height: 12),
          ],
          _opcao(
            contexto,
            const AnexarComprovante(OrigemComprovante.camera),
            Icons.photo_camera_outlined,
            'Tirar foto',
            'Fotografar o comprovante',
          ),
          const SizedBox(height: 12),
          _opcao(
            contexto,
            const AnexarComprovante(OrigemComprovante.galeria),
            Icons.photo_library_outlined,
            'Escolher da galeria',
            'Print ou foto já salva',
          ),
          const SizedBox(height: 12),
          _opcao(
            contexto,
            const AnexarComprovante(OrigemComprovante.pdf),
            Icons.picture_as_pdf_outlined,
            'Escolher PDF',
            'Comprovante do banco em PDF',
          ),
          const SizedBox(height: 16),
          BotaoApp.secundario(
            rotulo: 'Cancelar',
            onPressed: () => Navigator.of(contexto).pop(),
          ),
        ],
      ),
    );
  }

  static Widget _opcao(
    BuildContext contexto,
    AcaoComprovante acao,
    IconData icone,
    String titulo,
    String descricao,
  ) {
    return CartaoListaApp(
      titulo: titulo,
      subtitulo: descricao,
      inicio: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: CoresApp.primariaSuave,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icone, color: CoresApp.primaria),
      ),
      onTap: () => Navigator.of(contexto).pop(acao),
    );
  }
}
