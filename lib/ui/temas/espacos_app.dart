import 'package:flutter/widgets.dart';

/// Espaços fixos do app que garantem que nada fique colado na base da tela.
abstract final class EspacosApp {
  /// Folga extra abaixo de botões e folhas: em celulares com a barra ou a seta
  /// de navegação na base, o botão não fica por baixo dela.
  static const folgaInferior = 16.0;

  /// Distância da base para os botões flutuantes das listas. A altura da barra
  /// inferior do app chega como padding (a casca usa `extendBody`).
  static double baseDoBotaoFlutuante(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 16 + folgaInferior;
}
