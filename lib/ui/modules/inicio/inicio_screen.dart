// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/ui/modules/inicio/inicio_cubit.dart';
import 'package:sou_consultora/ui/modules/inicio/inicio_state.dart';
import 'package:sou_consultora/ui/modules/inicio/widgets/cabecalho_inicio.dart';
import 'package:sou_consultora/ui/modules/inicio/widgets/secao_alertas.dart';
import 'package:sou_consultora/ui/modules/inicio/widgets/secao_lembretes.dart';
import 'package:sou_consultora/ui/navegacao/casca/casca_principal_screen.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';

/// Início (item central da barra): painel do dia. Não cadastra nada; os
/// números, alertas e lembretes abrem os outros módulos.
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InicioCubit(),
      child: const _InicioVista(),
    );
  }
}

class _InicioVista extends StatelessWidget {
  const _InicioVista();

  void _aoAvisar(BuildContext context, InicioState estado) {
    final aviso = estado.aviso;
    if (aviso == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(aviso), behavior: SnackBarBehavior.floating),
      );
    context.read<InicioCubit>().limparAviso();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InicioCubit, InicioState>(
      listenWhen: (antes, depois) => antes.aviso != depois.aviso,
      listener: _aoAvisar,
      builder: (context, estado) {
        final pronto = estado.carregamento == CarregamentoInicio.pronto;
        return Column(
          children: [
            CabecalhoInicio(
              cumprimento: estado.cumprimento,
              consultora: estado.consultora,
              resumo: pronto ? estado.resumo : null,
              onMenu: () => CascaPrincipalScreen.abrirMenu(context),
              onVendas: () => context.go(RotasApp.vendas),
              onRecebido: () => context.go(RotasApp.aReceberPagas),
              onBoletos: () => context.go(RotasApp.aPagar),
            ),
            Expanded(child: _corpo(context, estado)),
          ],
        );
      },
    );
  }

  Widget _corpo(BuildContext context, InicioState estado) {
    final cubit = context.read<InicioCubit>();
    return switch (estado.carregamento) {
      CarregamentoInicio.carregando => const EstadoCarregandoApp(
        mensagem: 'Preparando o seu dia...',
      ),
      CarregamentoInicio.erro => EstadoErroApp(
        mensagem: estado.mensagemErro ?? 'Não foi possível carregar o Início.',
        onTentarNovamente: cubit.carregar,
      ),
      CarregamentoInicio.pronto => RefreshIndicator(
        onRefresh: cubit.carregar,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            24,
            16,
            // A casca usa `extendBody`: a barra inferior chega como padding.
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            SecaoAlertas(
              resumo: estado.resumo,
              onVerFatura: (id) => context.push(RotasApp.detalhesBoleto(id)),
              onCobrar: () => context.go(RotasApp.aReceberAtrasadas),
            ),
            const SizedBox(height: 28),
            SecaoLembretes(
              lembretes: estado.resumo.lembretes,
              onWhatsapp: cubit.lembrarRecompra,
              onVerTodos: () => context.go(RotasApp.clientes),
            ),
          ],
        ),
      ),
    };
  }
}
