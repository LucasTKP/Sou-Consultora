// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/core/model/detalhe_venda.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/venda.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/clientes/compras/clientes_compras_cubit.dart';
import 'package:sou_consultora/ui/modules/clientes/compras/clientes_compras_state.dart';
import 'package:sou_consultora/ui/modules/vendas/widgets/selos_venda.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_busca_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';

/// Compras da cliente: totais, filtro, busca e as vendas dela.
class ClientesComprasScreen extends StatelessWidget {
  const ClientesComprasScreen({super.key, required this.idCliente});

  final String idCliente;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClientesComprasCubit(idCliente: idCliente),
      child: _ComprasVista(idCliente: idCliente),
    );
  }
}

class _ComprasVista extends StatelessWidget {
  const _ComprasVista({required this.idCliente});

  final String idCliente;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientesComprasCubit, ClientesComprasState>(
      builder: (context, estado) => Scaffold(
        body: Column(
          children: [
            const CabecalhoApp(titulo: 'Compras da Cliente'),
            Expanded(child: _corpo(context, estado)),
            if (estado.compras?.vendas.isEmpty != true)
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: BotaoApp(
                  rotulo: 'Nova Venda',
                  onPressed: () =>
                      context.push(RotasApp.novaVendaPara(idCliente)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _corpo(BuildContext context, ClientesComprasState estado) {
    final compras = estado.compras;
    if (compras != null) return _Lista(estado: estado, compras: compras);
    final erro = estado.erro;
    if (erro != null) {
      return EstadoErroApp(
        mensagem: erro,
        onTentarNovamente: context.read<ClientesComprasCubit>().carregar,
      );
    }
    return const EstadoCarregandoApp();
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.estado, required this.compras});

  final ClientesComprasState estado;
  final ComprasCliente compras;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClientesComprasCubit>();
    final contagens = estado.contagens;
    final visiveis = estado.visiveis;
    final estilos = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        _Totais(estado: estado, compras: compras),
        const SizedBox(height: 16),
        if (compras.vendas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Text(
                  'Nenhuma compra ainda',
                  textAlign: TextAlign.center,
                  style: estilos.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Registre a primeira venda desta cliente.',
                  textAlign: TextAlign.center,
                  style: estilos.bodyLarge?.copyWith(
                    color: CoresApp.sobreSuperficieVariante,
                  ),
                ),
                const SizedBox(height: 24),
                BotaoApp(
                  rotulo: 'Registrar venda',
                  expande: false,
                  onPressed: () => context.push(
                    RotasApp.novaVendaPara(
                      context.read<ClientesComprasCubit>().idCliente,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          CampoSelecaoApp<StatusFiltroVenda>(
            rotulo: 'Filtrar por Status',
            opcoes: StatusFiltroVenda.values,
            rotuloDe: (s) => s == StatusFiltroVenda.todas
                ? 'Todas as compras (${contagens[s]})'
                : '${s.rotulo} (${contagens[s]})',
            valor: estado.status,
            onChanged: cubit.alterarStatus,
          ),
          const SizedBox(height: 16),
          CampoBuscaApp(
            rotulo: 'Buscar',
            placeholder: 'Buscar produto comprado...',
            onChanged: cubit.alterarBusca,
          ),
          const SizedBox(height: 16),
          if (visiveis.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Nenhuma compra encontrada',
                textAlign: TextAlign.center,
                style: estilos.bodyLarge?.copyWith(
                  color: CoresApp.sobreSuperficieVariante,
                ),
              ),
            ),
          for (final venda in visiveis) ...[
            _CartaoCompra(venda: venda),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _Totais extends StatelessWidget {
  const _Totais({required this.estado, required this.compras});

  final ClientesComprasState estado;
  final ComprasCliente compras;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final resumo = compras.resumo(hoje: estado.hoje);
    final nome = estado.clienteNome ?? '';
    return CartaoApp(
      filho: Column(
        children: [
          Row(
            children: [
              AvatarApp(iniciais: Cliente.iniciaisDe(nome)),
              const SizedBox(width: 16),
              Expanded(child: Text(nome, style: estilos.titleMedium)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TOTAL GASTO', style: estilos.labelSmall),
                  Text(
                    FormatadorMoeda.formatar(compras.totalGasto),
                    style: estilos.titleLarge?.copyWith(
                      color: CoresApp.primaria,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Bloco(
                  rotulo: 'ATRASADO',
                  valor: resumo.atrasado,
                  detalhe: resumo.qtdAtrasadas == 1
                      ? '1 vencida'
                      : '${resumo.qtdAtrasadas} vencidas',
                  fundo: CoresApp.perigoContainer,
                  cor: CoresApp.perigo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Bloco(
                  rotulo: 'PENDENTE',
                  valor: resumo.pendente,
                  detalhe: '${resumo.qtdPendentes} a vencer',
                  fundo: CoresApp.alertaContainer,
                  cor: CoresApp.alerta,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Bloco(
                  rotulo: 'PAGO',
                  valor: resumo.pago,
                  detalhe: resumo.qtdPagas == 1
                      ? '1 quitada'
                      : '${resumo.qtdPagas} quitadas',
                  fundo: CoresApp.sucessoContainer,
                  cor: CoresApp.sucesso,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco({
    required this.rotulo,
    required this.valor,
    required this.detalhe,
    required this.fundo,
    required this.cor,
  });

  final String rotulo;
  final int valor;
  final String detalhe;
  final Color fundo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(
          children: [
            Text(rotulo, style: estilos.labelSmall?.copyWith(color: cor)),
            FittedBox(
              child: Text(
                FormatadorMoeda.formatar(valor),
                style: estilos.titleSmall?.copyWith(color: cor),
              ),
            ),
            Text(
              detalhe,
              style: estilos.bodySmall?.copyWith(color: cor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoCompra extends StatelessWidget {
  const _CartaoCompra({required this.venda});

  final ResumoVenda venda;

  @override
  Widget build(BuildContext context) {
    return CartaoListaApp(
      titulo: venda.tituloItens,
      subtitulo:
          '${venda.qtdUnidades} un • ${FormatadorData.curta(venda.dataVenda)} • '
          '${FormatadorMoeda.formatar(venda.total)}',
      selo: SeloStatusVenda(status: venda.status),
      onTap: () => context.push(RotasApp.detalhesVenda(venda.id)),
    );
  }
}
