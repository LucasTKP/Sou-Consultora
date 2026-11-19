// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/categoria.dart';
import 'package:sou_consultora/core/model/ordem_nome.dart';
import 'package:sou_consultora/ui/modules/servicos/lista/servicos_lista_cubit.dart';
import 'package:sou_consultora/ui/modules/servicos/lista/servicos_lista_state.dart';
import 'package:sou_consultora/ui/modules/servicos/lista/widgets/cartao_servico.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_ordenacao_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_flutuante_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/texto_contagem_lista.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_busca_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';

/// Serviços abre pelo menu, sem a barra. Voltar retorna à aba de onde veio.
class ServicosListaScreen extends StatelessWidget {
  const ServicosListaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ServicosListaCubit(),
      child: const _ServicosListaVista(),
    );
  }
}

class _ServicosListaVista extends StatelessWidget {
  const _ServicosListaVista();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CabecalhoApp(titulo: 'Serviços', acao: AcaoCabecalho.voltar),
        Expanded(
          child: Stack(
            children: [
              BlocBuilder<ServicosListaCubit, ServicosListaState>(
                builder: _corpo,
              ),
              BlocBuilder<ServicosListaCubit, ServicosListaState>(
                builder: (context, estado) {
                  final vazio =
                      estado.carregamento == CarregamentoServicos.pronto &&
                      estado.todos.isEmpty;
                  if (vazio) return const SizedBox.shrink();
                  return Positioned(
                    right: 16,
                    // A casca usa `extendBody`: a altura da barra chega como padding.
                    bottom: MediaQuery.paddingOf(context).bottom + 16,
                    child: BotaoFlutuanteApp(
                      rotulo: 'Novo serviço',
                      onPressed: () => context.push(RotasApp.novoServico),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _corpo(BuildContext context, ServicosListaState estado) {
    return switch (estado.carregamento) {
      CarregamentoServicos.carregando => const EstadoCarregandoApp(
        mensagem: 'Carregando serviços...',
      ),
      CarregamentoServicos.erro => EstadoErroApp(
        mensagem:
            estado.mensagemErro ?? 'Não foi possível carregar os serviços.',
        onTentarNovamente: context.read<ServicosListaCubit>().carregar,
      ),
      CarregamentoServicos.pronto when estado.todos.isEmpty => EstadoVazioApp(
        titulo: 'Nenhum serviço ainda',
        mensagem: 'Cadastre os atendimentos que você oferece para vendê-los.',
        icone: Icons.spa_outlined,
        acao: BotaoApp(
          rotulo: 'Cadastrar serviço',
          expande: false,
          onPressed: () => context.push(RotasApp.novoServico),
        ),
      ),
      CarregamentoServicos.pronto => _Lista(estado: estado),
    };
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.estado});

  final ServicosListaState estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ServicosListaCubit>();
    final visiveis = estado.visiveis;
    final contagens = estado.contagens;
    final estilos = Theme.of(context).textTheme;
    final total = estado.todos.length;
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
            placeholder: 'Buscar serviço...',
            onChanged: cubit.alterarBusca,
          ),
          const SizedBox(height: 20),
          CampoSelecaoApp<Categoria?>(
            rotulo: 'Categoria',
            opcoes: [null, ...contagens.keys],
            rotuloDe: (c) => c == null
                ? 'Todos os serviços ($total)'
                : '${c.nome} (${contagens[c]})',
            valor: estado.categoria,
            placeholder: 'Todos os serviços',
            onChanged: cubit.alterarCategoria,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextoContagemLista(
                  total: total,
                  singular: 'serviço',
                  plural: 'serviços',
                ),
              ),
              BotaoOrdenacaoApp<OrdemNome>(
                opcoes: OrdemNome.values,
                rotuloDe: (ordem) => ordem.rotulo,
                valor: estado.ordem,
                onChanged: cubit.alterarOrdem,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (visiveis.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Nenhum serviço encontrado',
                textAlign: TextAlign.center,
                style: estilos.bodyLarge?.copyWith(
                  color: CoresApp.sobreSuperficieVariante,
                ),
              ),
            ),
          for (final servico in visiveis) ...[
            CartaoServico(
              servico: servico,
              onTap: () => context.push(RotasApp.detalhesServico(servico.id)),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
