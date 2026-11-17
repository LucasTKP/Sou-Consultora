// ignore_for_file: deprecated_member_use
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/origem_foto.dart';

/// Escolhe uma foto (câmera ou galeria) e recorta em 1:1.
abstract class ServicoFotoDispositivo {
  /// Sucesso(null) quando a pessoa desiste na escolha ou no recorte.
  Future<Resultado<Uint8List?>> escolherRecortada(OrigemFoto origem);
}

class ServicoFotoDispositivoNativo implements ServicoFotoDispositivo {
  ServicoFotoDispositivoNativo({ImagePicker? seletor, ImageCropper? recortador})
      : _seletor = seletor ?? ImagePicker(),
        _recortador = recortador ?? ImageCropper();

  final ImagePicker _seletor;
  final ImageCropper _recortador;

  // Cor primária do app (sem importar a camada ui).
  static const _corPrimaria = Color(0xFFB0396F);

  @override
  Future<Resultado<Uint8List?>> escolherRecortada(OrigemFoto origem) async {
    try {
      final arquivo = await _seletor.pickImage(
        source: origem == OrigemFoto.camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (arquivo == null) return const Sucesso(null);

      final recortado = await _recortar(arquivo.path);
      if (recortado == null) return const Sucesso(null);
      return Sucesso(await recortado.readAsBytes());
    } catch (_) {
      return const Erro(FalhaInesperada('Não foi possível abrir a câmera ou a galeria. Verifique as permissões do app.'));
    }
  }

  Future<CroppedFile?> _recortar(String caminho) {
    return _recortador.cropImage(
      sourcePath: caminho,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar foto',
          toolbarColor: _corPrimaria,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: _corPrimaria,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: 'Recortar foto',
          doneButtonTitle: 'Concluir',
          cancelButtonTitle: 'Cancelar',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );
  }
}
