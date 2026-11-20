// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_suporte/botao_suporte_cubit.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_suporte/botao_suporte_state.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';

/// "Falar com o suporte": abre o WhatsApp com a mensagem já escrita.
/// [detalhe] (o erro mostrado na tela) vai junto, para o suporte entender.
class BotaoSuporteApp extends StatelessWidget {
  const BotaoSuporteApp({super.key, this.detalhe});

  final String? detalhe;

  @override
  Widget build(BuildContext context) {
    // O cubit só é criado quando o botão é tocado (BlocProvider é preguiçoso).
    return BlocProvider(
      create: (_) => BotaoSuporteCubit(),
      child: _Vista(detalhe: detalhe),
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista({this.detalhe});

  final String? detalhe;

  void _aoMudar(BuildContext context, BotaoSuporteState estado) {
    final erro = estado.erro;
    if (erro == null) return;
    ToastApp.erro(context, erro);
    context.read<BotaoSuporteCubit>().limparErro();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BotaoSuporteCubit, BotaoSuporteState>(
      listener: _aoMudar,
      builder: (context, estado) {
        return TextButton.icon(
          onPressed: estado.abrindo
              ? null
              : () => context.read<BotaoSuporteCubit>().abrir(detalhe: detalhe),
          style: TextButton.styleFrom(foregroundColor: CoresApp.primaria),
          icon: const Icon(Icons.support_agent_rounded),
          label: const Text('Falar com o suporte'),
        );
      },
    );
  }
}
