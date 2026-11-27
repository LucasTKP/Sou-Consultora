// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/filtro_clientes.dart';
import 'package:sou_consultora/core/model/ordem_nome.dart';
import 'package:sou_consultora/ui/modules/clientes/lista/clientes_lista_cubit.dart';
import 'package:sou_consultora/ui/modules/clientes/lista/clientes_lista_state.dart';
import 'package:sou_consultora/ui/modules/clientes/lista/widgets/cartao_cliente.dart';
import 'package:sou_consultora/ui/navegacao/casca/casca_principal_screen.dart';
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
import 'package:sou_consultora/ui/temas/espacos_app.dart';

/// Tela principal de Clientes (dentro da casca, com a barra).
class ClientesListaScreen extends StatelessWidget {
  const ClientesListaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClientesListaCubit(),
      child: const _ClientesListaVista(),
    );
  }
}

class _ClientesListaVista extends StatelessWidget {
  const _ClientesListaVista();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CabecalhoApp(
          titulo: 'Clientes',
          acao: AcaoCabecalho.menu,
          onMenu: () => CascaPrincipalScreen.abrirMenu(context),
        ),
        Expanded(
          child: Stack(
            children: [
              BlocBuilder<ClientesListaCubit, ClientesListaState>(
                builder: _corpo,
              ),
              BlocBuilder<ClientesListaCubit, ClientesListaState>(
                builder: (context, estado) {
                  final vazio =
                      estado.carregamento == CarregamentoClientes.pronto &&
                      estado.todas.isEmpty;
                  if (vazio) return const SizedBox.shrink();
                  return Positioned(
                    right: 16,
                    // A casca usa `extendBody`: o fundo da tela fica atrás da
                    // barra inferior, cuja altura chega aqui como padding.
                    bottom: EspacosApp.baseDoBotaoFlutuante(context),
                    child: BotaoFlutuanteApp(
                      rotulo: 'Novo cliente',
                      icone: Icons.person_add_alt_1_outlined,
                      onPressed: () => context.push(RotasApp.novoCliente),
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

  Widget _corpo(BuildContext context, ClientesListaState estado) {
    return switch (estado.carregamento) {
      CarregamentoClientes.carregando => const EstadoCarregandoApp(
        mensagem: 'Carregando clientes...',
      ),
      CarregamentoClientes.erro => EstadoErroApp(
        mensagem:
            estado.mensagemErro ?? 'Não foi possível carregar as clientes.',
        onTentarNovamente: context.read<ClientesListaCubit>().carregar,
      ),
      CarregamentoClientes.pronto when estado.todas.isEmpty =>
        const _ListaVazia(),
      CarregamentoClientes.pronto => _Lista(estado: estado),
    };
  }
}

class _ListaVazia extends StatelessWidget {
  const _ListaVazia();

  @override
  Widget build(BuildContext context) {
    return EstadoVazioApp(
      titulo: 'Nenhuma cliente ainda',
      mensagem:
          'Cadastre a primeira cliente para registrar vendas e cobranças.',
      icone: Icons.people_alt_outlined,
      acao: BotaoApp(
        rotulo: 'Cadastrar cliente',
        expande: false,
        onPressed: () => context.push(RotasApp.novoCliente),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.estado});

  final ClientesListaState estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClientesListaCubit>();
    final visiveis = estado.visiveis;
    final contagens = estado.contagens;
    return RefreshIndicator(
      onRefresh: cubit.carregar,
      child: ListView(
        // Espaço no fim para a barra inferior e o botão flutuante não
        // cobrirem o último card.
        padding: EdgeInsets.fromLTRB(
          16,
          24,
          16,
          MediaQuery.paddingOf(context).bottom + 96 + EspacosApp.folgaInferior,
        ),
        children: [
          CampoSelecaoApp<StatusFiltroCliente>(
            rotulo: 'Status',
            opcoes: StatusFiltroCliente.values,
            rotuloDe: (status) => '${status.rotulo} (${contagens[status]})',
            valor: estado.status,
            onChanged: cubit.alterarStatus,
          ),
          const SizedBox(height: 20),
          CampoBuscaApp(
            rotulo: 'Buscar cliente',
            placeholder: 'Digite o nome do cliente...',
            onChanged: cubit.alterarBusca,
          ),
          const SizedBox(height: 16),
          _Resumo(
            total: estado.todas.length,
            ordem: estado.ordem,
            onChanged: cubit.alterarOrdem,
          ),
          const SizedBox(height: 8),
          if (visiveis.isEmpty) const _SemResultado(),
          for (final cliente in visiveis) ...[
            CartaoCliente(
              cliente: cliente,
              hoje: estado.hoje,
              onTap: () => context.push(RotasApp.detalhesCliente(cliente.id)),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({
    required this.total,
    required this.ordem,
    required this.onChanged,
  });

  final int total;
  final OrdemNome ordem;
  final ValueChanged<OrdemNome> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextoContagemLista(
            total: total,
            singular: 'cliente',
            plural: 'clientes',
          ),
        ),
        BotaoOrdenacaoApp<OrdemNome>(
          opcoes: OrdemNome.values,
          rotuloDe: (item) => item.rotulo,
          valor: ordem,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SemResultado extends StatelessWidget {
  const _SemResultado();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        'Nenhuma cliente encontrada',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: CoresApp.sobreSuperficieVariante),
      ),
    );
  }
}
