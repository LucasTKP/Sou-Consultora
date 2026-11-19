// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/modules/financeiro/financeiro_cubit.dart';
import 'package:sou_consultora/ui/modules/financeiro/financeiro_state.dart';
import 'package:sou_consultora/ui/modules/financeiro/widgets/cartao_categorias.dart';
import 'package:sou_consultora/ui/modules/financeiro/widgets/cartao_faturamento.dart';
import 'package:sou_consultora/ui/navegacao/casca/casca_principal_screen.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';

/// Financeiro (item da barra): período, faturamento dos últimos 12 meses e as
/// categorias do mês (A receber e A pagar). O botão do topo abre Nova venda.
class FinanceiroScreen extends StatelessWidget {
  const FinanceiroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FinanceiroCubit(),
      child: const _FinanceiroVista(),
    );
  }
}

class _FinanceiroVista extends StatelessWidget {
  const _FinanceiroVista();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CabecalhoApp(
          titulo: 'Financeiro',
          acao: AcaoCabecalho.menu,
          onMenu: () => CascaPrincipalScreen.abrirMenu(context),
          fim: _BotaoNovaVenda(
            onPressed: () => context.push(RotasApp.novaVenda),
          ),
        ),
        Expanded(
          child: BlocBuilder<FinanceiroCubit, FinanceiroState>(builder: _corpo),
        ),
      ],
    );
  }

  Widget _corpo(BuildContext context, FinanceiroState estado) {
    return switch (estado.carregamento) {
      CarregamentoFinanceiro.carregando => const EstadoCarregandoApp(
        mensagem: 'Calculando o financeiro...',
      ),
      CarregamentoFinanceiro.erro => EstadoErroApp(
        mensagem:
            estado.mensagemErro ?? 'Não foi possível carregar o financeiro.',
        onTentarNovamente: context.read<FinanceiroCubit>().carregar,
      ),
      CarregamentoFinanceiro.pronto => _Conteudo(estado: estado),
    };
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.estado});

  final FinanceiroState estado;

  String _rotuloPeriodo(MesAno mes) {
    final texto = FormatadorData.mesAnoPorExtenso(mes.ano, mes.mes);
    return mes == estado.mesAtual ? '$texto (Mês atual)' : texto;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FinanceiroCubit>();
    final resumo = estado.resumo;
    return RefreshIndicator(
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
          CampoSelecaoApp<MesAno>(
            rotulo: 'Período',
            opcoes: estado.periodos,
            rotuloDe: _rotuloPeriodo,
            valor: estado.periodo,
            icone: Icons.calendar_month_outlined,
            onChanged: cubit.alterarPeriodo,
          ),
          const SizedBox(height: 24),
          CartaoFaturamento(resumo: resumo),
          const SizedBox(height: 32),
          Text(
            'Categorias do Mês',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          CartaoCategorias(
            faturamento: resumo.faturamentoDoMes,
            despesas: resumo.despesasDoMes,
            onAReceber: () => context.push(RotasApp.aReceber),
            onAPagar: () => context.push(RotasApp.aPagar),
          ),
        ],
      ),
    );
  }
}

/// Botão redondo do topo: começa uma nova venda.
class _BotaoNovaVenda extends StatelessWidget {
  const _BotaoNovaVenda({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CoresApp.sobrePrimaria.withOpacity(0.18),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: 'Nova venda',
        onPressed: onPressed,
        icon: const Icon(
          Icons.add_shopping_cart_rounded,
          color: CoresApp.sobrePrimaria,
        ),
      ),
    );
  }
}
