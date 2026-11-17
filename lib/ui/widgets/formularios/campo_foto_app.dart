// ignore_for_file: deprecated_member_use
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/foto_quadrada_app.dart';

/// Campo de foto 1:1 dos cadastros (produto, serviço): mostra a foto nova,
/// a gravada ou o ícone de reserva. Tocar abre a escolha (câmera, galeria, remover).
class CampoFotoApp extends StatelessWidget {
  const CampoFotoApp({
    super.key,
    required this.onTap,
    this.fotoNova,
    this.urlFoto,
    this.descricao = 'Opcional · câmera ou galeria',
    this.rotuloAcessivel = 'foto',
  });

  final Uint8List? fotoNova;
  final String? urlFoto;
  final VoidCallback onTap;
  final String descricao;

  /// Ex.: "foto do produto" → "Adicionar foto do produto".
  final String rotuloAcessivel;

  @override
  Widget build(BuildContext context) {
    final temFoto = fotoNova != null || urlFoto != null;
    return Semantics(
      button: true,
      label: temFoto ? 'Trocar $rotuloAcessivel' : 'Adicionar $rotuloAcessivel',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            _miniatura(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    temFoto ? 'Trocar foto' : 'Adicionar foto',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: CoresApp.primaria),
                  ),
                  Text(descricao, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.photo_camera_outlined, color: CoresApp.primaria),
          ],
        ),
      ),
    );
  }

  Widget _miniatura() {
    final bytes = fotoNova;
    if (bytes == null) {
      return FotoQuadradaApp(
        url: urlFoto,
        tamanho: TamanhoAvatar.destaque,
        iconeReserva: Icons.add_a_photo_outlined,
      );
    }
    final lado = TamanhoAvatar.destaque.lado;
    return ClipRRect(
      borderRadius: BorderRadius.circular(lado * 0.22),
      child: Image.memory(bytes, width: lado, height: lado, fit: BoxFit.cover),
    );
  }
}
