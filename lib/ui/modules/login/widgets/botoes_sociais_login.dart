// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:sou_consultora/ui/modules/login/acesso_login_cubit.dart';
import 'package:sou_consultora/ui/modules/login/acesso_login_state.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Botões Google e Apple da tela de login.
class BotoesSociaisLogin extends StatelessWidget {
  const BotoesSociaisLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AcessoLoginCubit, AcessoLoginState>(
      builder: (context, estado) {
        final carregandoGoogle = estado is AcessoLoginCarregandoGoogle;
        final carregandoApple = estado is AcessoLoginCarregandoApple;
        final bloqueado = carregandoGoogle || carregandoApple;
        final cubit = context.read<AcessoLoginCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BotaoSocialLogin(
              rotulo: 'Continuar com Google',
              fundo: CoresApp.superficie,
              texto: CoresApp.sobreSuperficie,
              borda: CoresApp.contorno,
              carregando: carregandoGoogle,
              habilitado: !bloqueado,
              icone: SvgPicture.asset(
                'assets/imagens/logo_google.svg',
                width: 24,
                height: 24,
              ),
              onPressed: cubit.continuarComGoogle,
            ),
            if (!Platform.isAndroid) ...[
              const SizedBox(height: 14),
              _BotaoSocialLogin(
                rotulo: 'Continuar com Apple',
                fundo: CoresApp.botaoApple,
                texto: CoresApp.sobrePrimaria,
                borda: CoresApp.botaoApple,
                carregando: carregandoApple,
                habilitado: !bloqueado,
                icone: const Icon(
                  Icons.apple,
                  size: 24,
                  color: CoresApp.sobrePrimaria,
                ),
                onPressed: cubit.continuarComApple,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BotaoSocialLogin extends StatelessWidget {
  const _BotaoSocialLogin({
    required this.rotulo,
    required this.fundo,
    required this.texto,
    required this.borda,
    required this.icone,
    required this.onPressed,
    required this.carregando,
    required this.habilitado,
  });

  final String rotulo;
  final Color fundo;
  final Color texto;
  final Color borda;
  final Widget icone;
  final VoidCallback onPressed;
  final bool carregando;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final tipografia = Theme.of(context).textTheme;

    return SizedBox(
      height: 56,
      child: Material(
        color: fundo,
        elevation: fundo == CoresApp.superficie ? 0 : 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borda, width: 1.2),
        ),
        child: InkWell(
          onTap: habilitado && !carregando ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: habilitado ? 1 : 0.55,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (carregando)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: texto,
                      ),
                    )
                  else
                    icone,
                  const SizedBox(width: 12),
                  // Flexible evita estouro com fonte grande (acessibilidade) ou tela estreita.
                  Flexible(
                    child: Text(
                      rotulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tipografia.labelLarge?.copyWith(color: texto),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
