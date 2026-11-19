import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Tamanho do botão: [padrao] em rodapés e formulários de tela inteira;
/// [compacto] dentro de cartões e linhas de conteúdo.
enum TamanhoBotao {
  padrao(
    altura: 56,
    fonte: 17,
    paddingHorizontal: 20,
    paddingVertical: 12,
    tamanhoIcone: 24,
  ),
  compacto(
    altura: 36,
    fonte: 14,
    paddingHorizontal: 12,
    paddingVertical: 6,
    tamanhoIcone: 18,
  );

  const TamanhoBotao({
    required this.altura,
    required this.fonte,
    required this.paddingHorizontal,
    required this.paddingVertical,
    required this.tamanhoIcone,
  });

  final double altura;
  final double fonte;
  final double paddingHorizontal;
  final double paddingVertical;
  final double tamanhoIcone;
}

/// Botão do app (wrapper de [ShadButton]) — variantes do design system.
class BotaoApp extends StatelessWidget {
  const BotaoApp({
    super.key,
    required this.rotulo,
    this.onPressed,
    this.iconeFim,
    this.expande = true,
    this.tamanho = TamanhoBotao.padrao,
  }) : _variante = ShadButtonVariant.primary;

  const BotaoApp.contorno({
    super.key,
    required this.rotulo,
    this.onPressed,
    this.iconeFim,
    this.expande = true,
    this.tamanho = TamanhoBotao.padrao,
  }) : _variante = ShadButtonVariant.outline;

  /// Fundo suave (secundário / terciário do DS).
  const BotaoApp.secundario({
    super.key,
    required this.rotulo,
    this.onPressed,
    this.iconeFim,
    this.expande = true,
    this.tamanho = TamanhoBotao.padrao,
  }) : _variante = ShadButtonVariant.secondary;

  const BotaoApp.perigo({
    super.key,
    required this.rotulo,
    this.onPressed,
    this.iconeFim,
    this.expande = true,
    this.tamanho = TamanhoBotao.padrao,
  }) : _variante = ShadButtonVariant.destructive;

  final String rotulo;
  final VoidCallback? onPressed;
  final Widget? iconeFim;
  final bool expande;
  final TamanhoBotao tamanho;
  final ShadButtonVariant _variante;

  /// Ícone proporcional ao tamanho do botão.
  Widget? _icone(Widget? icone) {
    if (icone == null) return null;
    return IconTheme.merge(
      data: IconThemeData(size: tamanho.tamanhoIcone),
      child: icone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = Text(
      rotulo,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
    // O rótulo encolhe com reticências se a largura acabar (fonte grande ou
    // botões lado a lado). Sem `expande`, o botão acompanha o texto.
    final rotuloWidget = Flexible(fit: FlexFit.loose, child: texto);

    final estiloTema = switch (_variante) {
      ShadButtonVariant.primary =>
        ShadTheme.of(context).primaryButtonTheme.textStyle,
      ShadButtonVariant.outline =>
        ShadTheme.of(context).outlineButtonTheme.textStyle,
      ShadButtonVariant.secondary =>
        ShadTheme.of(context).secondaryButtonTheme.textStyle,
      ShadButtonVariant.destructive =>
        ShadTheme.of(context).destructiveButtonTheme.textStyle,
      _ => null,
    };

    final estilo = tamanho == TamanhoBotao.padrao
        ? null
        : (estiloTema ?? const TextStyle()).copyWith(
            fontSize: tamanho.fonte,
            fontWeight: FontWeight.w600,
            height: 1.2,
          );

    final altura = tamanho == TamanhoBotao.padrao ? null : tamanho.altura;
    final padding = tamanho == TamanhoBotao.padrao
        ? null
        : EdgeInsets.symmetric(
            horizontal: tamanho.paddingHorizontal,
            vertical: tamanho.paddingVertical,
          );

    return ShadButton.raw(
      variant: _variante,
      onPressed: onPressed,
      expands: expande,
      height: altura,
      padding: padding,
      textStyle: estilo,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          rotuloWidget,
          if (iconeFim != null) ...[
            SizedBox(width: tamanho == TamanhoBotao.compacto ? 6 : 8),
            _icone(iconeFim)!,
          ],
        ],
      ),
    );
  }
}
