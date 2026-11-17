// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/filtro_fornecedores.dart';
import 'package:sou_consultora/core/model/ordem_nome.dart';
import 'package:sou_consultora/ui/modules/fornecedores/lista/fornecedores_lista_cubit.dart';
import 'package:sou_consultora/ui/modules/fornecedores/lista/fornecedores_lista_state.dart';
import 'package:sou_consultora/ui/modules/fornecedores/lista/widgets/cartao_fornecedor.dart';
import 'package:sou_consultora/ui/navegacao/casca/casca_principal_screen.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_flutuante_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_busca_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';

/// Tela principal de Fornecedores (dentro da casca, aberta pelo menu lateral).
class FornecedoresListaScreen extends StatelessWidget {
  const FornecedoresListaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FornecedoresListaCubit(),
      child: const _FornecedoresListaVista(),
    );
  }
}

class _FornecedoresListaVista extends StatelessWidget {
  const _FornecedoresListaVista();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CabecalhoApp(
          titulo: 'Fornecedores',
          acao: AcaoCabecalho.menu,
          onMenu: () => CascaPrincipalScreen.abrirMenu(context),
        ),
        Expanded(
          child: Stack(
            children: [
              BlocBuilder<FornecedoresListaCubit, FornecedoresListaState>(
                builder: _corpo,
              ),
              Positioned(
                right: 16,
                // A casca usa `extendBody`: o fundo da tela fica atrás da
                // barra inferior, cuja altura chega aqui como padding.
                bottom: MediaQuery.paddingOf(context).bottom + 16,
                child: BotaoFlutuanteApp(
                  rotulo: 'Fornecedor',
                  onPressed: () => context.push(RotasApp.novoFornecedor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _corpo(BuildContext context, FornecedoresListaState estado) {
    return switch (estado.carregamento) {
      CarregamentoFornecedores.carregando => const EstadoCarregandoApp(
        mensagem: 'Carregando fornecedores...',
      ),
      CarregamentoFornecedores.erro => EstadoErroApp(
        mensagem:
            estado.mensagemErro ?? 'Não foi possível carregar os fornecedores.',
        onTentarNovamente: context.read<FornecedoresListaCubit>().carregar,
      ),
      CarregamentoFornecedores.pronto when estado.todos.isEmpty =>
        const _ListaVazia(),
      CarregamentoFornecedores.pronto => _Lista(estado: estado),
    };
  }
}

class _ListaVazia extends StatelessWidget {
  const _ListaVazia();

  @override
  Widget build(BuildContext context) {
    return EstadoVazioApp(
      titulo: 'Nenhum fornecedor ainda',
      mensagem: 'Cadastre as marcas de quem você compra para lançar produtos e boletos.',
      icone: Icons.local_shipping_outlined,
      acao: BotaoApp(
        rotulo: 'Cadastrar fornecedor',
        expande: false,
        iconeInicio: const Icon(Icons.add_rounded),
        onPressed: () => context.push(RotasApp.novoFornecedor),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.estado});

  final FornecedoresListaState estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FornecedoresListaCubit>();
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
          MediaQuery.paddingOf(context).bottom + 96,
        ),
        children: [
          CampoBuscaApp(
            rotulo: 'Buscar',
            placeholder: 'Buscar fornecedor ou marca...',
            onChanged: cubit.alterarBusca,
          ),
          const SizedBox(height: 20),
          CampoSelecaoApp<StatusFiltroFornecedor>(
            rotulo: 'Status',
            opcoes: StatusFiltroFornecedor.values,
            rotuloDe: (status) => '${status.rotulo} (${contagens[status]})',
            valor: estado.status,
            onChanged: cubit.alterarStatus,
          ),
          const SizedBox(height: 16),
          _Resumo(
            total: estado.todos.length,
            ordem: estado.ordem,
            onInverter: cubit.inverterOrdem,
          ),
          const SizedBox(height: 8),
          if (visiveis.isEmpty) const _SemResultado(),
          for (final fornecedor in visiveis) ...[
            CartaoFornecedor(
              fornecedor: fornecedor,
              onTap: () =>
                  context.push(RotasApp.detalhesFornecedor(fornecedor.id)),
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
    required this.onInverter,
  });

  final int total;
  final OrdemNome ordem;
  final VoidCallback onInverter;

  @override
  Widget build(BuildContext context) {
    final texto = total == 1 ? '1 fornecedor' : '$total fornecedores';
    return Row(
      children: [
        Expanded(
          child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton.icon(
          onPressed: onInverter,
          icon: const Icon(Icons.swap_vert_rounded),
          label: Text(ordem.rotulo),
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
        'Nenhum fornecedor encontrado',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: CoresApp.sobreSuperficieVariante),
      ),
    );
  }
}
