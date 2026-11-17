// ignore_for_file: deprecated_member_use
import 'package:sou_consultora/ui/modules/login/acesso_login_cubit.dart';
import 'package:sou_consultora/ui/modules/login/acesso_login_state.dart';
import 'package:sou_consultora/ui/modules/login/widgets/botoes_sociais_login.dart';
import 'package:sou_consultora/ui/modules/login/widgets/cabecalho_marca_login.dart';
import 'package:sou_consultora/ui/modules/login/widgets/cartao_boas_vindas_login.dart';
import 'package:sou_consultora/ui/modules/login/widgets/fundo_acesso.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AcessoLoginScreen extends StatelessWidget {
  const AcessoLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AcessoLoginCubit(),
      child: const _AcessoLoginVista(),
    );
  }
}

class _AcessoLoginVista extends StatelessWidget {
  const _AcessoLoginVista();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AcessoLoginCubit, AcessoLoginState>(
      listener: _aoMudarEstado,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FundoAcesso(
          filho: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: const IntrinsicHeight(
                      child: Column(
                        children: [
                          SizedBox(height: 36),
                          CabecalhoMarcaLogin(),
                          Spacer(flex: 1),
                          CartaoBoasVindasLogin(),
                          SizedBox(height: 24),
                          BotoesSociaisLogin(),
                          Spacer(flex: 2),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// O sucesso não precisa de ação: o roteador leva ao Início quando a sessão começa.
  void _aoMudarEstado(BuildContext context, AcessoLoginState estado) {
    if (estado is! AcessoLoginErro) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            estado.mensagem,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: CoresApp.sobrePrimaria),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    context.read<AcessoLoginCubit>().limparErro();
  }
}
