// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/duracao_servico.dart';
import 'package:sou_consultora/core/model/resumo_servico.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/servicos/detalhes/servicos_detalhes_cubit.dart';
import 'package:sou_consultora/ui/modules/servicos/detalhes/servicos_detalhes_state.dart';
import 'package:sou_consultora/ui/modules/servicos/widgets/icone_servico.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';
import 'package:sou_consultora/ui/temas/espacos_app.dart';

/// Detalhes de um serviço. Não existe exclusão.
class ServicosDetalhesScreen extends StatelessWidget {
  const ServicosDetalhesScreen({super.key, required this.idServico});

  final String idServico;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ServicosDetalhesCubit(idServico: idServico),
      child: const _DetalhesVista(),
    );
  }
}

class _DetalhesVista extends StatelessWidget {
  const _DetalhesVista();

  void _aoAvisar(BuildContext context, ServicosDetalhesState estado) {
    final aviso = estado.aviso;
    if (aviso == null) return;
    ToastApp.mostrar(context, aviso);
    context.read<ServicosDetalhesCubit>().limparAviso();
  }

  Future<void> _editar(BuildContext context, String id) async {
    final cubit = context.read<ServicosDetalhesCubit>();
    final salvou = await context.push<bool>(RotasApp.editarServico(id));
    if (salvou == true) await cubit.carregar();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ServicosDetalhesCubit, ServicosDetalhesState>(
      listenWhen: (antes, depois) => antes.aviso != depois.aviso,
      listener: _aoAvisar,
      builder: (context, estado) {
        final servico = estado.servico;
        return Scaffold(
          body: Column(
            children: [
              const CabecalhoApp(titulo: 'Detalhes do Serviço'),
              Expanded(child: _corpo(context, estado)),
              if (servico != null)
                SafeArea(
                  top: false,
                  minimum: EspacosApp.margemRodape,
                  child: BotaoApp(
                    rotulo: 'Editar Serviço',
                    onPressed: () => _editar(context, servico.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _corpo(BuildContext context, ServicosDetalhesState estado) {
    final servico = estado.servico;
    if (servico != null) return _Conteudo(servico: servico);
    final erro = estado.erro;
    if (erro != null) {
      return EstadoErroApp(
        mensagem: erro,
        onTentarNovamente: context.read<ServicosDetalhesCubit>().carregar,
      );
    }
    return const EstadoCarregandoApp();
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.servico});

  final ResumoServico servico;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final retorno = servico.retorno;
    final custo = servico.custoMateriais;
    final duracao = servico.duracaoMinutos;
    final observacoes = servico.observacoes;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        CartaoApp(
          filho: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconeServico(
                    categoria: servico.categoriaNome,
                    urlFoto: servico.urlFoto,
                    tamanho: TamanhoAvatar.destaque,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SeloStatusApp(
                          tamanho: TamanhoSelo.pagina,
                          rotulo: servico.categoriaNome.toUpperCase(),
                        ),
                        const SizedBox(height: 4),
                        Text(servico.nome, style: estilos.titleLarge),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: CoresApp.primariaSuave),
              Text(
                'PREÇO COBRADO',
                style: estilos.labelMedium?.copyWith(
                  color: CoresApp.sobreSuperficieVariante,
                ),
              ),
              Text(
                FormatadorMoeda.formatar(servico.precoCobrado),
                style: estilos.headlineMedium?.copyWith(
                  color: CoresApp.primaria,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Bloco(
                rotulo: 'Custo de materiais',
                valor: custo == null
                    ? 'Não informado'
                    : FormatadorMoeda.formatar(custo),
                fundo: CoresApp.primariaSuave,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Bloco(
                rotulo: 'Lucro',
                valor: FormatadorMoeda.formatar(retorno.valor),
                fundo: CoresApp.sucessoContainer,
                cor: CoresApp.sucesso,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CartaoApp(
          filho: Column(
            children: [
              if (duracao != null)
                _Linha(
                  icone: Icons.schedule_rounded,
                  rotulo: 'DURAÇÃO ESTIMADA',
                  valor: '${DuracaoServico.curto(duracao)} ($duracao min)',
                ),
              _Linha(
                icone: Icons.category_outlined,
                rotulo: 'CATEGORIA',
                valor: servico.categoriaNome,
              ),
              if (observacoes != null)
                _Linha(
                  icone: Icons.notes_rounded,
                  rotulo: 'OBSERVAÇÕES / DESCRIÇÃO',
                  valor: observacoes,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco({
    required this.rotulo,
    required this.valor,
    required this.fundo,
    this.detalhe,
    this.cor,
  });

  final String rotulo;
  final String valor;
  final String? detalhe;
  final Color fundo;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rotulo, style: estilos.bodySmall?.copyWith(color: cor)),
            const SizedBox(height: 4),
            Text(valor, style: estilos.titleMedium?.copyWith(color: cor)),
            if (detalhe != null)
              Text(detalhe!, style: estilos.bodySmall?.copyWith(color: cor)),
          ],
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.icone,
    required this.rotulo,
    required this.valor,
  });

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: CoresApp.sobreSuperficieVariante),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: estilos.labelSmall?.copyWith(
                    color: CoresApp.sobreSuperficieVariante,
                  ),
                ),
                Text(valor, style: estilos.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
