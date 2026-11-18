import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';

/// Abre o compartilhar do celular com uma imagem PNG e um texto curto.
abstract interface class ServicoCompartilhar {
  Future<Resultado<void>> compartilharImagem({
    required Uint8List png,
    required String nomeArquivo,
    required String texto,
  });
}

class ServicoCompartilharNativo implements ServicoCompartilhar {
  static const _falha = FalhaInesperada('Não foi possível compartilhar.');

  @override
  Future<Resultado<void>> compartilharImagem({
    required Uint8List png,
    required String nomeArquivo,
    required String texto,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: texto,
          files: [
            XFile.fromData(png, mimeType: 'image/png', name: nomeArquivo),
          ],
          fileNameOverrides: [nomeArquivo],
        ),
      );
      return const Sucesso(null);
    } catch (erro, pilha) {
      return Erro(_falha, causa: erro, pilha: pilha);
    }
  }
}
