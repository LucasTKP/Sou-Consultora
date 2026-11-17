// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/texto_busca.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/foto_quadrada_app.dart';

/// Foto do serviço ou, sem foto, o ícone da categoria (unhas → mão etc.).
class IconeServico extends StatelessWidget {
  const IconeServico({
    super.key,
    required this.categoria,
    this.urlFoto,
    this.tamanho = TamanhoAvatar.card,
  });

  final String categoria;
  final String? urlFoto;
  final TamanhoAvatar tamanho;

  @override
  Widget build(BuildContext context) {
    return FotoQuadradaApp(
      url: urlFoto,
      tamanho: tamanho,
      iconeReserva: iconeDaCategoria(categoria),
    );
  }

  static IconData iconeDaCategoria(String categoria) {
    final nome = TextoBusca.normalizar(categoria);
    if (nome.contains('unha')) return Icons.back_hand_outlined;
    if (nome.contains('maquiagem')) return Icons.brush_outlined;
    if (nome.contains('sobrancelha')) return Icons.visibility_outlined;
    if (nome.contains('facial') || nome.contains('pele')) {
      return Icons.spa_outlined;
    }
    return Icons.auto_awesome_outlined;
  }

  /// Cor usada nos selos de categoria.
  static const corCategoria = CoresApp.primariaEscura;
}
