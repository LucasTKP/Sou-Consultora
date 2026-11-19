// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/ui/modules/atualizacao/atualizacao_cubit.dart';
import 'package:sou_consultora/ui/modules/atualizacao/atualizacao_state.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';

/// Tela única quando a versão instalada está abaixo do mínimo: não há como sair dela.
class AtualizacaoScreen extends StatelessWidget {
  const AtualizacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AtualizacaoCubit(),
      child: const _AtualizacaoVista(),
    );
  }
}

class _AtualizacaoVista extends StatelessWidget {
  const _AtualizacaoVista();

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return BlocListener<AtualizacaoCubit, AtualizacaoState>(
      listener: (context, estado) {
        if (estado is! AtualizacaoErro) return;
        ToastApp.erro(context, estado.mensagem);
        context.read<AtualizacaoCubit>().limparErro();
      },
      child: Scaffold(
        backgroundColor: CoresApp.fundo,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(),
                Image.asset('assets/imagens/logo.png', width: 112, height: 112),
                const SizedBox(height: 24),
                Text(
                  'Atualização necessária',
                  textAlign: TextAlign.center,
                  style: estilos.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Esta versão do app não é mais compatível. '
                  'Atualize na loja para continuar usando.',
                  textAlign: TextAlign.center,
                  style: estilos.bodyLarge,
                ),
                const Spacer(),
                BlocBuilder<AtualizacaoCubit, AtualizacaoState>(
                  builder: (context, estado) => BotaoApp(
                    rotulo: 'Atualizar agora',
                    onPressed: estado is AtualizacaoAbrindoLoja
                        ? null
                        : context.read<AtualizacaoCubit>().abrirLoja,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
