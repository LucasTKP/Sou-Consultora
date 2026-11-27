// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';

/// Foto sempre 1:1, recorte `cover` e cantos arredondados (diretriz do DS).
/// Sem foto ou com falha ao carregar → ícone de reserva.
class FotoQuadradaApp extends StatelessWidget {
  const FotoQuadradaApp({
    super.key,
    this.url,
    this.tamanho = TamanhoAvatar.card,
    this.iconeReserva = Icons.inventory_2_outlined,
  });

  final String? url;
  final TamanhoAvatar tamanho;
  final IconData iconeReserva;

  @override
  Widget build(BuildContext context) {
    final lado = tamanho.lado;
    return ClipRRect(
      borderRadius: BorderRadius.circular(lado * 0.22),
      child: SizedBox.square(
        dimension: lado,
        child: url == null || url!.isEmpty ? _reserva(lado) : _imagem(lado),
      ),
    );
  }

  Widget _imagem(double lado) {
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _reserva(lado),
    );
  }

  Widget _reserva(double lado) {
    return ColoredBox(
      color: CoresApp.primariaSuave,
      child: Icon(iconeReserva, color: CoresApp.primaria, size: lado * 0.45),
    );
  }
}
