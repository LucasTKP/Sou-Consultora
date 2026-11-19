// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/filtro_boletos.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/modules/a_pagar/lista/a_pagar_lista_cubit.dart';
import 'package:sou_consultora/ui/modules/a_pagar/lista/a_pagar_lista_state.dart';
import 'package:sou_consultora/ui/modules/a_pagar/lista/widgets/cartao_boleto.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_flutuante_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_ordenacao_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/texto_contagem_lista.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_busca_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';

/// A pagar abre sem a barra (pelo menu ou por uma marca). Voltar retorna à aba.
class APagarListaScreen extends StatelessWidget {
  const APagarListaScreen({super.key, this.fornecedorId});

  final String? fornecedorId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => APagarListaCubit(fornecedorId: fornecedorId),
      child: fornecedorId == null ? const _APagarListaVista() : const Scaffold(body: _APagarListaVista()),
    );
  }
}

class _APagarListaVista extends StatelessWidget {
  const _APagarListaVista();

  void _novo(BuildContext context) {
    final cubit = context.read<APagarListaCubit>();
    context.push(RotasApp.novoBoleto(fornecedorId: cubit.fornecedorId));
  }

  @override
  Widget build(BuildContext context) {
    // A casca usa `extendBody`: a altura da barra inferior chega como padding.
    final baixo = MediaQuery.paddingOf(context).bottom;
    return BlocBuilder<APagarListaCubit, APagarListaState>(
      builder: (context, estado) => Column(
        children: [
          CabecalhoApp(titulo: 'A pagar', subtitulo: estado.nomeFornecedor, acao: AcaoCabecalho.voltar),
          Expanded(
            child: Stack(
              children: [
                _corpo(context, estado),
                if (estado.carregamento != CarregamentoBoletos.pronto ||
                    estado.todos.isNotEmpty)
                  Positioned(
                    right: 16,
                    bottom: baixo + 16,
                    child: BotaoFlutuanteApp(
                      rotulo: 'Novo boleto',
                      onPressed: () => _novo(context),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _corpo(BuildContext context, APagarListaState estado) {
    return switch (estado.carregamento) {
      CarregamentoBoletos.carregando => const EstadoCarregandoApp(mensagem: 'Carregando boletos...'),
      CarregamentoBoletos.erro => EstadoErroApp(
        mensagem: estado.mensagemErro ?? 'Não foi possível carregar os boletos.',
        onTentarNovamente: context.read<APagarListaCubit>().carregar,
      ),
      CarregamentoBoletos.pronto when estado.todos.isEmpty => EstadoVazioApp(
        titulo: 'Nenhum boleto ainda',
        mensagem: 'Lance os boletos das marcas para não perder o vencimento.',
        icone: Icons.receipt_long_outlined,
        acao: BotaoApp(
          rotulo: 'Lançar boleto',
          expande: false,
          onPressed: () => _novo(context),
        ),
      ),
      CarregamentoBoletos.pronto => _Lista(estado: estado),
    };
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.estado});

  final APagarListaState estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<APagarListaCubit>();
    final visiveis = estado.visiveis;
    final contagens = estado.contagens;
    final estilos = Theme.of(context).textTheme;
    final total = visiveis.length;
    return RefreshIndicator(
      onRefresh: cubit.carregar,
      child: ListView(
        // Espaço no fim para a barra inferior e o botão flutuante não
        // cobrirem o último card.
        padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.paddingOf(context).bottom + 96),
        children: [
          CampoBuscaApp(
            rotulo: 'Buscar contas',
            placeholder: 'Buscar por marca ou observação...',
            onChanged: cubit.alterarBusca,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CampoSelecaoApp<StatusFiltroBoleto>(
                  rotulo: 'Status',
                  opcoes: StatusFiltroBoleto.values,
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
                  rotuloDe: (m) => m == null ? 'Todos os meses' : FormatadorData.mesAnoAbreviado(m.ano, m.mes),
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
                  singular: 'boleto',
                  plural: 'boletos',
                ),
              ),
              Flexible(
                child: BotaoOrdenacaoApp<OrdemBoleto>(
                  opcoes: OrdemBoleto.values,
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
                'Nenhum boleto encontrado',
                textAlign: TextAlign.center,
                style: estilos.bodyLarge?.copyWith(color: CoresApp.sobreSuperficieVariante),
              ),
            ),
          for (final boleto in visiveis) ...[
            CartaoBoleto(
              boleto: boleto,
              hoje: estado.hoje,
              onTap: () => context.push(RotasApp.detalhesBoleto(boleto.id)),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

}
