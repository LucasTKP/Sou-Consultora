import 'package:flutter/widgets.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';

/// Mostra [erro] como toast (uma vez por mensagem nova) e devolve [child] como está.
///
/// Padrão do app: erros não aparecem escritos na tela, só em toast. Quando o
/// erro some (null), a próxima mensagem volta a disparar o toast.
class ErroEmToast extends StatefulWidget {
  const ErroEmToast({super.key, required this.erro, this.child});

  final String? erro;
  final Widget? child;

  @override
  State<ErroEmToast> createState() => _ErroEmToastState();
}

class _ErroEmToastState extends State<ErroEmToast> {
  @override
  void initState() {
    super.initState();
    _avisar(widget.erro);
  }

  @override
  void didUpdateWidget(ErroEmToast antigo) {
    super.didUpdateWidget(antigo);
    if (widget.erro != antigo.erro) _avisar(widget.erro);
  }

  void _avisar(String? erro) {
    if (erro == null || erro.trim().isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ToastApp.erro(context, erro);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}
