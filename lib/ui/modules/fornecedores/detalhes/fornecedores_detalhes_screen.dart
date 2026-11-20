// ignore_for_file: deprecated_member_use
import 'package:sou_consultora/ui/widgets/estrutura/rodape_seguro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_telefone.dart';
import 'package:sou_consultora/ui/modules/fornecedores/detalhes/fornecedores_detalhes_cubit.dart';
import 'package:sou_consultora/ui/modules/fornecedores/detalhes/fornecedores_detalhes_state.dart';
import 'package:sou_consultora/ui/modules/fornecedores/detalhes/widgets/cartao_boletos.dart';
import 'package:sou_consultora/ui/modules/fornecedores/widgets/selo_status_fornecedor.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';

/// Detalhes de um fornecedor. Não existe exclusão: para deixar de usar a
/// marca, a consultora a coloca em espera na edição.
class FornecedoresDetalhesScreen extends StatelessWidget {
  const FornecedoresDetalhesScreen({super.key, required this.idFornecedor});

  final String idFornecedor;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FornecedoresDetalhesCubit(idFornecedor: idFornecedor),
      child: const _DetalhesVista(),
    );
  }
}

class _DetalhesVista extends StatelessWidget {
  const _DetalhesVista();

  void _aoAvisar(BuildContext context, FornecedoresDetalhesState estado) {
    final aviso = estado.aviso;
    if (aviso == null) return;
    ToastApp.mostrar(context, aviso);
    context.read<FornecedoresDetalhesCubit>().limparAviso();
  }

  Future<void> _editar(BuildContext context, String id) async {
    final cubit = context.read<FornecedoresDetalhesCubit>();
    final salvou = await context.push<bool>(RotasApp.editarFornecedor(id));
    if (salvou == true) await cubit.carregar();
  }

  /// A pagar só com os boletos da marca; na volta, o resumo é recarregado
  /// (boletos pagos, lançados ou excluídos lá).
  Future<void> _verEmAPagar(BuildContext context, String id) async {
    final cubit = context.read<FornecedoresDetalhesCubit>();
    await context.push(RotasApp.boletosDoFornecedor(id));
    await cubit.carregar();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FornecedoresDetalhesCubit, FornecedoresDetalhesState>(
      listenWhen: (antes, depois) => antes.aviso != depois.aviso,
      listener: _aoAvisar,
      builder: (context, estado) {
        final fornecedor = estado.fornecedor;
        return Scaffold(
          body: Column(
            children: [
              const CabecalhoApp(titulo: 'Detalhes do Fornecedor'),
              Expanded(child: _corpo(context, estado)),
              if (fornecedor != null)
                RodapeSeguro(
                  child: BotaoApp(
                    rotulo: 'Editar Fornecedor',
                    onPressed: () => _editar(context, fornecedor.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _corpo(BuildContext context, FornecedoresDetalhesState estado) {
    final fornecedor = estado.fornecedor;
    if (fornecedor != null) {
      return _Conteudo(
        fornecedor: fornecedor,
        onVerEmAPagar: () => _verEmAPagar(context, fornecedor.id),
      );
    }
    final erro = estado.erro;
    if (erro != null) {
      return EstadoErroApp(
        mensagem: erro,
        onTentarNovamente: context.read<FornecedoresDetalhesCubit>().carregar,
      );
    }
    return const EstadoCarregandoApp();
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.fornecedor, required this.onVerEmAPagar});

  final ResumoFornecedor fornecedor;
  final VoidCallback onVerEmAPagar;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        _Identidade(fornecedor: fornecedor),
        const SizedBox(height: 16),
        CartaoBoletos(fornecedor: fornecedor, onVerEmAPagar: onVerEmAPagar),
        if (_temContato) ...[
          const SizedBox(height: 16),
          _Contato(fornecedor: fornecedor),
        ],
      ],
    );
  }

  bool get _temContato =>
      fornecedor.contato != null ||
      fornecedor.telefone != null ||
      fornecedor.observacoes != null;
}

class _Identidade extends StatelessWidget {
  const _Identidade({required this.fornecedor});

  final ResumoFornecedor fornecedor;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final ramo = fornecedor.ramo;
    return _Secao(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarApp(
                iniciais: fornecedor.iniciais,
                tamanho: TamanhoAvatar.destaque,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fornecedor.nome, style: estilos.titleLarge),
                    if (ramo != null)
                      Text(
                        ramo,
                        style: estilos.bodyMedium?.copyWith(
                          color: CoresApp.sobreSuperficieVariante,
                        ),
                      ),
                    const SizedBox(height: 8),
                    SeloStatusFornecedor(
                      tamanho: TamanhoSelo.pagina,
                      fornecedor: fornecedor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 24,
                color: CoresApp.sobreSuperficieVariante,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Parceiro desde ${FormatadorData.mesAnoCurto(fornecedor.criadoEm)}',
                  style: estilos.bodyMedium?.copyWith(
                    color: CoresApp.sobreSuperficieVariante,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Contato extends StatelessWidget {
  const _Contato({required this.fornecedor});

  final ResumoFornecedor fornecedor;

  @override
  Widget build(BuildContext context) {
    final contato = fornecedor.contato;
    final telefone = fornecedor.telefone;
    final observacoes = fornecedor.observacoes;
    final linhas = <Widget>[
      if (contato != null)
        _Linha(
          icone: Icons.person_outline_rounded,
          rotulo: 'Contato / representante',
          valor: contato,
        ),
      if (telefone != null)
        _Linha(
          icone: Icons.phone_outlined,
          rotulo: 'Telefone',
          valor: FormatadorTelefone.formatar(telefone),
          fim: BotaoApp.contorno(
            rotulo: 'WhatsApp',
            tamanho: TamanhoBotao.compacto,
            expande: false,
            onPressed: context.read<FornecedoresDetalhesCubit>().abrirWhatsapp,
          ),
        ),
      if (observacoes != null)
        _Linha(
          icone: Icons.notes_rounded,
          rotulo: 'Observações',
          valor: observacoes,
        ),
    ];
    return _Secao(
      child: Column(
        children: [
          for (var i = 0; i < linhas.length; i++) ...[
            if (i > 0) const Divider(height: 24),
            linhas[i],
          ],
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.icone,
    required this.rotulo,
    required this.valor,
    this.fim,
  });

  final IconData icone;
  final String rotulo;
  final String valor;
  final Widget? fim;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, color: CoresApp.sobreSuperficieVariante),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rotulo.toUpperCase(),
                style: estilos.labelSmall?.copyWith(
                  color: CoresApp.sobreSuperficieVariante,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(valor, style: estilos.bodyLarge),
            ],
          ),
        ),
        if (fim != null) ...[const SizedBox(width: 8), fim!],
      ],
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoresApp.primariaSuave),
      ),
      child: child,
    );
  }
}
