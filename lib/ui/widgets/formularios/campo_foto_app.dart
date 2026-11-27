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
    this.compacto = false,
  });

  final Uint8List? fotoNova;
  final String? urlFoto;
  final VoidCallback onTap;
  final String descricao;

  /// Ex.: "foto do produto" → "Adicionar foto do produto".
  final String rotuloAcessivel;

  /// Só a miniatura, com um quadrado de câmera sobre a foto.
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final temFoto = fotoNova != null || urlFoto != null;
    if (compacto) {
      return Center(
        child: Semantics(
          button: true,
          label: temFoto
              ? 'Trocar $rotuloAcessivel'
              : 'Adicionar $rotuloAcessivel',
          child: InkWell(
            onTap: onTap,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _miniatura(comBorda: true),
                const Positioned(
                  right: -4,
                  bottom: -4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: CoresApp.primaria,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      border: Border.fromBorderSide(
                        BorderSide(color: CoresApp.superficie, width: 2),
                      ),
                    ),
                    child: SizedBox.square(
                      dimension: 28,
                      child: Icon(
                        Icons.photo_camera_outlined,
                        color: CoresApp.sobrePrimaria,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
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

  Widget _miniatura({bool comBorda = false}) {
    final lado = TamanhoAvatar.destaque.lado;
    final raio = BorderRadius.circular(lado * 0.22);
    final bytes = fotoNova;
    final Widget foto;
    if (bytes == null) {
      foto = FotoQuadradaApp(
        url: urlFoto,
        tamanho: TamanhoAvatar.destaque,
        iconeReserva: Icons.add_a_photo_outlined,
      );
    } else {
      foto = ClipRRect(
        borderRadius: raio,
        child: Image.memory(
          bytes,
          width: lado,
          height: lado,
          fit: BoxFit.cover,
        ),
      );
    }
    if (!comBorda) return foto;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: raio,
        border: Border.all(color: CoresApp.contorno, width: 1.5),
      ),
      child: foto,
    );
  }
}
