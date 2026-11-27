// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';
import 'package:toastification/toastification.dart';

/// Toasts do app: erro, aviso e sucesso, com as cores de status.
abstract final class ToastApp {
  static const _duracao = Duration(seconds: 4);

  /// Largura e margem usadas em todo o app (e nos testes).
  static ToastificationConfig configuracao(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    return ToastificationConfig(
      alignment: Alignment.topCenter,
      itemWidth: (largura - 32).clamp(280, 440).toDouble(),
      animationDuration: const Duration(milliseconds: 250),
      maxTitleLines: 4,
      marginBuilder: (context, _) {
        final topo = MediaQuery.paddingOf(context).top;
        return EdgeInsets.only(top: topo + 12);
      },
    );
  }

  static void erro(BuildContext context, String mensagem) =>
      mostrar(context, AvisoToast.erro(mensagem));

  static void aviso(BuildContext context, String mensagem) =>
      mostrar(context, AvisoToast.aviso(mensagem));

  static void sucesso(BuildContext context, String mensagem) =>
      mostrar(context, AvisoToast.sucesso(mensagem));

  static void mostrar(BuildContext context, AvisoToast aviso) {
    final (fundo, icone, tipo) = switch (aviso.tipo) {
      TipoToast.erro => (
        CoresApp.perigo,
        Icons.warning_amber_rounded,
        ToastificationType.error,
      ),
      TipoToast.aviso => (
        CoresApp.alerta,
        Icons.warning_amber_rounded,
        ToastificationType.warning,
      ),
      TipoToast.sucesso => (
        CoresApp.sucesso,
        Icons.check_circle_outline_rounded,
        ToastificationType.success,
      ),
    };
    const letra = CoresApp.sobrePrimaria;

    toastification.dismissAll(delayForAnimation: false);
    toastification.show(
      context: context,
      type: tipo,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: _duracao,
      alignment: Alignment.topCenter,
      title: Text(
        aviso.mensagem,
        style: const TextStyle(
          color: letra,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
      icon: Icon(icone, size: 24, color: letra),
      primaryColor: fundo,
      backgroundColor: letra,
      foregroundColor: letra,
      borderRadius: BorderRadius.circular(14),
      showProgressBar: false,
      closeOnClick: true,
      dragToClose: true,
      applyBlurEffect: false,
      pauseOnHover: false,
      closeButton: ToastCloseButton(
        buttonBuilder: (context, fechar) => IconButton(
          tooltip: 'Fechar aviso',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          onPressed: fechar,
          icon: const Icon(Icons.close_rounded, size: 24, color: letra),
        ),
      ),
    );
  }
}
