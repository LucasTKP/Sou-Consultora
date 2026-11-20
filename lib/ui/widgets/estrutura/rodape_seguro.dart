import 'package:flutter/widgets.dart';

/// Rodapé de botão fixo: soma a área segura do aparelho (barra de navegação,
/// seta de voltar, indicador de gestos) a uma folga fixa, em vez de usar o
/// maior dos dois como o `SafeArea.minimum`.
class RodapeSeguro extends StatelessWidget {
  const RodapeSeguro({super.key, required this.child});

  /// Folga entre a área segura do aparelho e o botão.
  static const folga = 24.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final area = MediaQuery.paddingOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24 + area.left,
        12,
        24 + area.right,
        folga + area.bottom,
      ),
      child: child,
    );
  }
}
