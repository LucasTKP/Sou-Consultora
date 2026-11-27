import 'package:flutter/material.dart';

/// Total de uma lista, no mesmo tamanho em todas as telas.
///
/// "1 produto" no singular e "2 produtos" no plural.
class TextoContagemLista extends StatelessWidget {
  const TextoContagemLista({
    super.key,
    required this.total,
    required this.singular,
    required this.plural,
  });

  final int total;
  final String singular;
  final String plural;

  @override
  Widget build(BuildContext context) {
    final texto = total == 1 ? '1 $singular' : '$total $plural';
    return Text(texto, style: Theme.of(context).textTheme.titleMedium);
  }
}
