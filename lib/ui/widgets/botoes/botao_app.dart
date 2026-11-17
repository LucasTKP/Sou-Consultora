import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Botão do app (wrapper de [ShadButton]) — variantes do design system.
class BotaoApp extends StatelessWidget {
  const BotaoApp({
    super.key,
    required this.rotulo,
    this.onPressed,
    this.iconeInicio,
    this.iconeFim,
    this.expande = true,
  }) : _variante = ShadButtonVariant.primary;

  const BotaoApp.contorno({
    super.key,
    required this.rotulo,
    this.onPressed,
    this.iconeInicio,
    this.iconeFim,
    this.expande = true,
  }) : _variante = ShadButtonVariant.outline;

  /// Fundo suave (secundário / terciário do DS).
  const BotaoApp.secundario({
    super.key,
    required this.rotulo,
    this.onPressed,
    this.iconeInicio,
    this.iconeFim,
    this.expande = true,
  }) : _variante = ShadButtonVariant.secondary;

  const BotaoApp.perigo({
    super.key,
    required this.rotulo,
    this.onPressed,
    this.iconeInicio,
    this.iconeFim,
    this.expande = true,
  }) : _variante = ShadButtonVariant.destructive;

  final String rotulo;
  final VoidCallback? onPressed;
  final Widget? iconeInicio;
  final Widget? iconeFim;
  final bool expande;
  final ShadButtonVariant _variante;

  @override
  Widget build(BuildContext context) {
    return ShadButton.raw(
      variant: _variante,
      onPressed: onPressed,
      leading: iconeInicio,
      trailing: iconeFim,
      expands: expande,
      child: Text(rotulo),
    );
  }
}
