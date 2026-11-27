// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

/// Segunda linha dos cards de lista: a situação em cor e negrito, seguida dos
/// detalhes em texto normal, tudo separado por " · " e em uma linha só
/// ("Atrasada 15/10 · R$ 120,00 · Parcela 2/3"). Se faltar espaço, as
/// reticências cortam o fim, nunca o status.
///
/// É o padrão no lugar do selo ao lado do nome (ver `.claude/rules/cards-lista.md`).
class LinhaSituacaoApp extends StatelessWidget {
  const LinhaSituacaoApp({
    super.key,
    required this.status,
    required this.cor,
    this.detalhes = const [],
  });

  /// Situação em destaque ("2 atrasadas · R$ 1.250,00", "Em dia").
  final String status;
  final Color cor;

  /// O que vem depois do status, na ordem de importância.
  final List<String> detalhes;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: status,
            style: TextStyle(color: cor, fontWeight: FontWeight.w700),
          ),
          for (final detalhe in detalhes) TextSpan(text: ' · $detalhe'),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
