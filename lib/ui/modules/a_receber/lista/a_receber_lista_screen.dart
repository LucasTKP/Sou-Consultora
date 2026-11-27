// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/filtro_recebimentos.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/modules/a_receber/lista/a_receber_lista_cubit.dart';
import 'package:sou_consultora/ui/modules/a_receber/lista/a_receber_lista_state.dart';
import 'package:sou_consultora/ui/modules/a_receber/lista/widgets/cartao_parcela.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_ordenacao_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/texto_contagem_lista.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_busca_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';

/// A receber abre pelo menu ou pelo Início, sem a barra. Voltar retorna à aba.
class AReceberListaScreen extends StatelessWidget {
  const AReceberListaScreen({super.key, this.statusInicial});

  /// Filtro já escolhido (Início: Cobrar agora → Atrasado; Recebido → Pago).
  final StatusFiltroRecebimento? statusInicial;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AReceberListaCubit(statusInicial: statusInicial),
      child: const _AReceberListaVista(),
    );
  }
}

class _AReceberListaVista extends StatelessWidget {
  const _AReceberListaVista();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CabecalhoApp(titulo: 'Recebimentos', acao: AcaoCabecalho.voltar),
        Expanded(
          child: BlocBuilder<AReceberListaCubit, AReceberListaState>(
            builder: _corpo,
          ),
        ),
      ],
    );
  }

  Widget _corpo(BuildContext context, AReceberListaState estado) {
    return switch (estado.carregamento) {
      CarregamentoRecebimentos.carregando => const EstadoCarregandoApp(
        mensagem: 'Carregando parcelas...',
      ),
      CarregamentoRecebimentos.erro => EstadoErroApp(
        mensagem:
            estado.mensagemErro ?? 'Não foi possível carregar as parcelas.',
        onTentarNovamente: context.read<AReceberListaCubit>().carregar,
      ),
      CarregamentoRecebimentos.pronto when estado.todas.isEmpty =>
        EstadoVazioApp(
          titulo: 'Nada a receber',
          mensagem: 'Registre uma venda para acompanhar as parcelas por aqui.',
          icone: Icons.payments_outlined,
          acao: BotaoApp(
            rotulo: 'Registrar venda',
            expande: false,
            onPressed: () => context.push(RotasApp.novaVenda),
          ),
        ),
      CarregamentoRecebimentos.pronto => _Lista(estado: estado),
    };
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.estado});

  final AReceberListaState estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AReceberListaCubit>();
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
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          CampoBuscaApp(
            rotulo: 'Buscar',
            placeholder: 'Buscar por cliente ou produto...',
            onChanged: cubit.alterarBusca,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CampoSelecaoApp<StatusFiltroRecebimento>(
                  rotulo: 'Status',
                  opcoes: StatusFiltroRecebimento.values,
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
                child: TextoContagemLista(
                  total: total,
                  singular: 'parcela',
                  plural: 'parcelas',
                ),
              ),
              Flexible(
                child: BotaoOrdenacaoApp<OrdemRecebimento>(
                  opcoes: OrdemRecebimento.values,
                  rotuloDe: (ordem) => ordem.rotulo,
                  valor: estado.ordem,
                  onChanged: cubit.alterarOrdem,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (visiveis.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Nenhuma parcela encontrada',
                textAlign: TextAlign.center,
                style: estilos.bodyLarge?.copyWith(
                  color: CoresApp.sobreSuperficieVariante,
                ),
              ),
            ),
          for (final parcela in visiveis) ...[
            CartaoParcela(
              parcela: parcela,
              hoje: estado.hoje,
              onTap: () => context.push(RotasApp.detalhesParcela(parcela.id)),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
