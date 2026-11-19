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
import 'package:sou_consultora/ui/widgets/botoes/botao_flutuante_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';

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
    ToastApp.mostrar(context, aviso);
    context.read<InicioCubit>().limparAviso();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InicioCubit, InicioState>(
      listenWhen: (antes, depois) => antes.aviso != depois.aviso,
      listener: _aoAvisar,
      builder: (context, estado) {
        final pronto = estado.carregamento == CarregamentoInicio.pronto;
        return Stack(
          children: [
            Column(
              children: [
                CabecalhoInicio(
                  consultora: estado.consultora,
                  resumo: pronto ? estado.resumo : null,
                  onMenu: () => CascaPrincipalScreen.abrirMenu(context),
                  onPerfil: () => context.push(RotasApp.perfil),
                  onVendas: () => context.go(RotasApp.vendas),
                  onRecebido: () => context.push(RotasApp.aReceberPagas),
                  onBoletos: () => context.push(RotasApp.aPagar),
                ),
                Expanded(child: _corpo(context, estado)),
              ],
            ),
            // Fora do corpo, para aparecer também quando o Início dá erro:
            // é justamente aí que a consultora mais precisa pedir ajuda.
            Positioned(
              right: 16,
              // A casca usa `extendBody`: a barra inferior chega como padding.
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: BotaoFlutuanteApp(
                rotulo: 'Ajuda',
                icone: Icons.support_agent_rounded,
                onPressed: context.read<InicioCubit>().falarComSuporte,
              ),
            ),
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
            // O resto é folga para o botão "Ajuda" não cobrir o último cartão.
            MediaQuery.paddingOf(context).bottom + 96,
          ),
          children: [
            SecaoAlertas(
              resumo: estado.resumo,
              onVerFatura: (id) => context.push(RotasApp.detalhesBoleto(id)),
              onCobrar: () => context.push(RotasApp.aReceberAtrasadas),
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
