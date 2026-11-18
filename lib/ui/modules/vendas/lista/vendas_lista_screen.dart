// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/modules/vendas/lista/vendas_lista_cubit.dart';
import 'package:sou_consultora/ui/modules/vendas/lista/vendas_lista_state.dart';
import 'package:sou_consultora/ui/modules/vendas/lista/widgets/cartao_venda.dart';
import 'package:sou_consultora/ui/navegacao/casca/casca_principal_screen.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_flutuante_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_busca_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';

/// Tela principal de Vendas (item da barra inferior).
class VendasListaScreen extends StatelessWidget {
  const VendasListaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendasListaCubit(),
      child: const _VendasListaVista(),
    );
  }
}

class _VendasListaVista extends StatelessWidget {
  const _VendasListaVista();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CabecalhoApp(
          titulo: 'Vendas & Pedidos',
          acao: AcaoCabecalho.menu,
          onMenu: () => CascaPrincipalScreen.abrirMenu(context),
        ),
        Expanded(
          child: Stack(
            children: [
              BlocBuilder<VendasListaCubit, VendasListaState>(builder: _corpo),
              Positioned(
                right: 16,
                bottom: MediaQuery.paddingOf(context).bottom + 16,
                child: BotaoFlutuanteApp(
                  rotulo: 'Nova venda',
                  onPressed: () => context.push(RotasApp.novaVenda),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _corpo(BuildContext context, VendasListaState estado) {
    return switch (estado.carregamento) {
      CarregamentoVendas.carregando => const EstadoCarregandoApp(
        mensagem: 'Carregando vendas...',
      ),
      CarregamentoVendas.erro => EstadoErroApp(
        mensagem: estado.mensagemErro ?? 'Não foi possível carregar as vendas.',
        onTentarNovamente: context.read<VendasListaCubit>().carregar,
      ),
      CarregamentoVendas.pronto when estado.todas.isEmpty => EstadoVazioApp(
        titulo: 'Nenhuma venda ainda',
        mensagem: 'Registre o primeiro pedido para acompanhar os pagamentos.',
        icone: Icons.receipt_long_outlined,
        acao: BotaoApp(
          rotulo: 'Registrar venda',
          expande: false,
          iconeInicio: const Icon(Icons.add_rounded),
          onPressed: () => context.push(RotasApp.novaVenda),
        ),
      ),
      CarregamentoVendas.pronto => _Lista(estado: estado),
    };
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.estado});

  final VendasListaState estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VendasListaCubit>();
    final visiveis = estado.visiveis;
    final contagens = estado.contagens;
    final estilos = Theme.of(context).textTheme;
    final total = visiveis.length;
    return RefreshIndicator(
      onRefresh: cubit.carregar,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          24,
          16,
          MediaQuery.paddingOf(context).bottom + 96,
        ),
        children: [
          CampoBuscaApp(
            rotulo: 'Buscar',
            placeholder: 'Buscar por cliente, produto ou código...',
            onChanged: cubit.alterarBusca,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CampoSelecaoApp<StatusFiltroVenda>(
                  rotulo: 'Status',
                  opcoes: StatusFiltroVenda.values,
                  rotuloDe: (s) => '${s.rotulo} (${contagens[s]})',
                  valor: estado.status,
                  onChanged: cubit.alterarStatus,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CampoSelecaoApp<MesAno?>(
                  rotulo: 'Mês/Ano',
                  opcoes: [...estado.meses, null],
                  rotuloDe: (m) => m == null
                      ? 'Todos os meses'
                      : FormatadorData.mesAnoAbreviado(m.ano, m.mes),
                  valor: estado.mes,
                  placeholder: 'Todos os meses',
                  onChanged: cubit.alterarMes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  total == 1 ? '1 venda realizada' : '$total vendas realizadas',
                  style: estilos.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: cubit.inverterOrdem,
                icon: const Icon(Icons.swap_vert_rounded),
                label: Text(estado.ordem.rotulo),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (visiveis.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Nenhuma venda encontrada',
                textAlign: TextAlign.center,
                style: estilos.bodyLarge?.copyWith(
                  color: CoresApp.sobreSuperficieVariante,
                ),
              ),
            ),
          for (final venda in visiveis) ...[
            CartaoVenda(
              venda: venda,
              hoje: estado.hoje,
              onTap: () => context.push(RotasApp.detalhesVenda(venda.id)),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
