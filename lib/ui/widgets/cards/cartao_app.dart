import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Card do app (wrapper de [ShadCard]).
class CartaoApp extends StatelessWidget {
  const CartaoApp({
    super.key,
    this.titulo,
    this.descricao,
    this.filho,
    this.rodape,
    this.inicio,
    this.fim,
    this.onTap,
    this.espacamento,
  });

  final Widget? titulo;
  final Widget? descricao;
  final Widget? filho;
  final Widget? rodape;
  final Widget? inicio;
  final Widget? fim;
  final VoidCallback? onTap;

  /// Padding interno; null usa o padrão do [ShadCard].
  final EdgeInsetsGeometry? espacamento;

  @override
  Widget build(BuildContext context) {
    final cartao = ShadCard(
      title: titulo,
      description: descricao,
      leading: inicio,
      trailing: fim,
      footer: rodape,
      padding: espacamento,
      child: filho,
    );

    if (onTap == null) return cartao;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: cartao,
    );
  }
}
