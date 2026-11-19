// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/resumo_cliente.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/clientes/detalhes/clientes_detalhes_cubit.dart';
import 'package:sou_consultora/ui/modules/clientes/detalhes/clientes_detalhes_state.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/cards/grupo_navegacao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/temas/espacos_app.dart';

class ClientesDetalhesScreen extends StatelessWidget {
  const ClientesDetalhesScreen({super.key, required this.idCliente});

  final String idCliente;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClientesDetalhesCubit(idCliente: idCliente),
      child: const _DetalhesVista(),
    );
  }
}

class _DetalhesVista extends StatelessWidget {
  const _DetalhesVista();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientesDetalhesCubit, ClientesDetalhesState>(
      builder: (context, estado) {
        final resumo = estado.resumo;
        return Scaffold(
          body: Column(
            children: [
              const CabecalhoApp(titulo: 'Detalhes do Cliente'),
              Expanded(child: _corpo(context, estado)),
              if (resumo != null)
                SafeArea(
                  top: false,
                  minimum: EspacosApp.margemRodape,
                  child: BotaoApp(
                    rotulo: 'Nova Venda',
                    onPressed: () =>
                        context.push(RotasApp.novaVendaPara(resumo.id)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _corpo(BuildContext context, ClientesDetalhesState estado) {
    final resumo = estado.resumo;
    if (resumo != null) return _Conteudo(resumo: resumo);
    final erro = estado.erro;
    if (erro != null) {
      return EstadoErroApp(
        mensagem: erro,
        onTentarNovamente: context.read<ClientesDetalhesCubit>().carregar,
      );
    }
    return const EstadoCarregandoApp();
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.resumo});

  final ResumoCliente resumo;

  String get _descricaoCompras {
    if (resumo.qtdCompras == 0) return 'Nenhum pedido ainda';
    final pedidos = resumo.qtdCompras == 1
        ? '1 pedido'
        : '${resumo.qtdCompras} pedidos';
    return '$pedidos • ${FormatadorMoeda.formatar(resumo.totalCompras)} total gasto';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Center(
          child: AvatarApp(
            iniciais: resumo.iniciais,
            tamanho: TamanhoAvatar.destaque,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          resumo.nome,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (resumo.comSaldo) ...[
          const SizedBox(height: 12),
          Center(
            child: SeloStatusApp(
              tamanho: TamanhoSelo.pagina,
              rotulo: 'Deve ${FormatadorMoeda.formatar(resumo.saldoDevedor)}',
              status: StatusSelo.perigo,
            ),
          ),
        ],
        const SizedBox(height: 32),
        GrupoNavegacaoApp(
          itens: [
            ItemNavegacaoApp(
              icone: Icons.badge_outlined,
              titulo: 'Dados Cadastrais',
              descricao: 'Telefone, endereço e notas',
              onTap: () => context.push(RotasApp.dadosCliente(resumo.id)),
            ),
            ItemNavegacaoApp(
              icone: Icons.shopping_bag_outlined,
              titulo: 'Compras da Cliente',
              descricao: _descricaoCompras,
              corIcone: CoresApp.alerta,
              corFundoIcone: CoresApp.alertaContainer,
              onTap: () => context.push(RotasApp.comprasCliente(resumo.id)),
            ),
          ],
        ),
      ],
    );
  }
}
