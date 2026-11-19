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
import 'package:sou_consultora/ui/widgets/botoes/botao_flutuante_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';

/// Financeiro (item da barra): período, faturamento dos últimos 12 meses e as
/// categorias do mês (A receber e A pagar). O botão flutuante abre Nova venda.
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
    final baixo = MediaQuery.paddingOf(context).bottom;
    return Column(
      children: [
        CabecalhoApp(
          titulo: 'Financeiro',
          acao: AcaoCabecalho.menu,
          onMenu: () => CascaPrincipalScreen.abrirMenu(context),
        ),
        Expanded(
          child: Stack(
            children: [
              BlocBuilder<FinanceiroCubit, FinanceiroState>(builder: _corpo),
              Positioned(
                right: 16,
                bottom: baixo + 16,
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
          // Espaço no fim para a barra inferior e o botão flutuante não
          // cobrirem o último card.
          MediaQuery.paddingOf(context).bottom + 96,
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
