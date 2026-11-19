// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/a_pagar/detalhes/a_pagar_detalhes_cubit.dart';
import 'package:sou_consultora/ui/modules/a_pagar/detalhes/a_pagar_detalhes_state.dart';
import 'package:sou_consultora/ui/modules/a_pagar/detalhes/widgets/folha_comprovante.dart';
import 'package:sou_consultora/ui/modules/a_pagar/detalhes/widgets/folha_opcoes_boleto.dart';
import 'package:sou_consultora/ui/modules/a_pagar/detalhes/widgets/folha_pagar_boleto.dart';
import 'package:sou_consultora/ui/modules/a_pagar/widgets/selo_status_boleto.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/dialogo_confirmacao_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/toast_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';

/// Detalhes do boleto: valor, marca, vencimento, forma, situação, observação
/// e comprovante; Confirmar pagamento (não pago) e Mais opções.
class APagarDetalhesScreen extends StatelessWidget {
  const APagarDetalhesScreen({super.key, required this.idBoleto});

  final String idBoleto;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => APagarDetalhesCubit(idBoleto: idBoleto),
      child: const _DetalhesVista(),
    );
  }
}

class _DetalhesVista extends StatelessWidget {
  const _DetalhesVista();

  void _aoMudarEstado(BuildContext context, APagarDetalhesState estado) {
    if (estado.excluido) {
      Navigator.of(context).pop(true);
      return;
    }
    final aviso = estado.aviso;
    if (aviso == null) return;
    ToastApp.mostrar(context, aviso);
    context.read<APagarDetalhesCubit>().limparAviso();
  }

  Future<void> _pagar(BuildContext context, APagarDetalhesState estado) {
    return FolhaPagarBoleto.mostrar(
      context,
      cubit: context.read<APagarDetalhesCubit>(),
      valor: estado.boleto!.valor,
      hoje: estado.hoje,
    );
  }

  Future<void> _opcoes(BuildContext context, ResumoBoleto boleto) async {
    final opcao = await FolhaOpcoesBoleto.mostrar(context, pago: boleto.pago);
    if (!context.mounted) return;
    switch (opcao) {
      case null:
        return;
      case OpcaoBoleto.editar:
        await _editar(context, boleto.id);
      case OpcaoBoleto.comprovante:
        await _comprovante(context, boleto);
      case OpcaoBoleto.desfazer:
        await _confirmarDesfazer(context);
      case OpcaoBoleto.excluir:
        await _confirmarExclusao(context, boleto);
    }
  }

  Future<void> _editar(BuildContext context, String id) async {
    final cubit = context.read<APagarDetalhesCubit>();
    final salvou = await context.push<bool>(RotasApp.editarBoleto(id));
    if (salvou == true) await cubit.carregar();
  }

  Future<void> _comprovante(BuildContext context, ResumoBoleto boleto) async {
    final cubit = context.read<APagarDetalhesCubit>();
    final acao = await FolhaComprovante.mostrar(
      context,
      temComprovante: boleto.temComprovante,
    );
    switch (acao) {
      case null:
        return;
      case VerComprovante():
        await cubit.verComprovante();
      case AnexarComprovante(:final origem):
        await cubit.anexarComprovante(origem);
    }
  }

  Future<void> _confirmarDesfazer(BuildContext context) async {
    final cubit = context.read<APagarDetalhesCubit>();
    final confirmou = await DialogoConfirmacaoApp.mostrar(
      context: context,
      titulo: 'Desfazer o pagamento?',
      mensagem:
          'O boleto volta a ficar em aberto. A forma de pagamento e o '
          'comprovante continuam guardados.',
      rotuloConfirmar: 'Desfazer',
      rotuloCancelar: 'Voltar',
    );
    if (confirmou) await cubit.desfazerPagamento();
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
    ResumoBoleto boleto,
  ) async {
    final cubit = context.read<APagarDetalhesCubit>();
    final confirmou = await DialogoConfirmacaoApp.mostrar(
      context: context,
      titulo: 'Excluir este boleto?',
      mensagem:
          'O boleto da ${boleto.fornecedorNome} de '
          '${FormatadorMoeda.formatar(boleto.valor)} e o comprovante serão '
          'apagados. Não dá para desfazer.',
      rotuloConfirmar: 'Excluir boleto',
      rotuloCancelar: 'Voltar',
      perigo: true,
    );
    if (confirmou) await cubit.excluir();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<APagarDetalhesCubit, APagarDetalhesState>(
      listenWhen: (antes, depois) =>
          antes.aviso != depois.aviso || antes.excluido != depois.excluido,
      listener: _aoMudarEstado,
      builder: (context, estado) => Scaffold(
        body: Column(
          children: [
            const CabecalhoApp(titulo: 'Detalhes do Boleto'),
            Expanded(child: _corpo(context, estado)),
            if (estado.boleto != null) _rodape(context, estado),
          ],
        ),
      ),
    );
  }

  Widget _corpo(BuildContext context, APagarDetalhesState estado) {
    final boleto = estado.boleto;
    if (boleto != null) {
      return _Conteudo(
        boleto: boleto,
        hoje: estado.hoje,
        onVerComprovante: context.read<APagarDetalhesCubit>().verComprovante,
      );
    }
    final erro = estado.erro;
    if (erro != null) {
      return EstadoErroApp(
        mensagem: erro,
        onTentarNovamente: context.read<APagarDetalhesCubit>().carregar,
      );
    }
    return const EstadoCarregandoApp();
  }

  Widget _rodape(BuildContext context, APagarDetalhesState estado) {
    final boleto = estado.boleto!;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!boleto.pago) ...[
            BotaoApp(
              rotulo: 'Confirmar Pagamento',
              onPressed: estado.ocupado ? null : () => _pagar(context, estado),
            ),
            const SizedBox(height: 12),
          ],
          BotaoApp.secundario(
            rotulo: _rotuloOpcoes(estado.acao),
            onPressed: estado.ocupado ? null : () => _opcoes(context, boleto),
          ),
        ],
      ),
    );
  }

  static String _rotuloOpcoes(AcaoBoleto acao) => switch (acao) {
    AcaoBoleto.desfazendo => 'Desfazendo...',
    AcaoBoleto.excluindo => 'Excluindo...',
    AcaoBoleto.anexando => 'Enviando comprovante...',
    AcaoBoleto.abrindo => 'Abrindo comprovante...',
    _ => 'Mais opções',
  };
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({
    required this.boleto,
    required this.hoje,
    required this.onVerComprovante,
  });

  final ResumoBoleto boleto;
  final DateTime hoje;
  final VoidCallback onVerComprovante;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final status = boleto.status(hoje: hoje);
    final observacoes = boleto.observacoes;
    final pagoEm = boleto.dataPagamento;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: CoresApp.primariaSuave,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 24,
                  color: CoresApp.primaria,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    boleto.fornecedorNome,
                    overflow: TextOverflow.ellipsis,
                    style: estilos.titleSmall?.copyWith(
                      color: CoresApp.primaria,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          boleto.pago ? 'VALOR PAGO' : 'VALOR A PAGAR',
          textAlign: TextAlign.center,
          style: estilos.labelLarge?.copyWith(
            color: CoresApp.sobreSuperficieVariante,
          ),
        ),
        Text(
          FormatadorMoeda.formatar(boleto.valor),
          textAlign: TextAlign.center,
          style: estilos.displaySmall?.copyWith(
            color: boleto.pago ? CoresApp.sucesso : null,
          ),
        ),
        const SizedBox(height: 24),
        _Quadro(
          linhas: [
            _Linha(
              icone: Icons.storefront_outlined,
              rotulo: 'Fornecedor',
              valor: Text(boleto.fornecedorNome, textAlign: TextAlign.end),
            ),
            _Linha(
              icone: Icons.event_outlined,
              rotulo: 'Vencimento',
              valor: Text(
                FormatadorData.curta(boleto.vencimento),
                style: TextStyle(
                  color: status == StatusBoleto.atrasado
                      ? CoresApp.perigo
                      : CoresApp.primaria,
                ),
              ),
            ),
            _Linha(
              icone: Icons.account_balance_wallet_outlined,
              rotulo: 'Forma de pagamento',
              valor: Text(boleto.forma?.rotulo ?? 'Não informada'),
            ),
            _Linha(
              icone: Icons.info_outline_rounded,
              rotulo: 'Status',
              valor: SeloStatusBoleto(tamanho: TamanhoSelo.pagina, status: status),
            ),
            if (pagoEm != null)
              _Linha(
                icone: Icons.event_available_outlined,
                rotulo: 'Pago em',
                valor: Text(
                  FormatadorData.curta(pagoEm),
                  style: const TextStyle(color: CoresApp.sucesso),
                ),
              ),
            if (boleto.temComprovante)
              _Linha(
                icone: boleto.comprovanteEmPdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.image_outlined,
                rotulo: 'Comprovante',
                valor: TextButton(
                  onPressed: onVerComprovante,
                  child: const Text('Ver comprovante'),
                ),
              ),
          ],
        ),
        if (observacoes != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CoresApp.primariaSuave.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CoresApp.contorno),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notes_rounded,
                  color: CoresApp.sobreSuperficieVariante,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(observacoes, style: estilos.bodyLarge)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Quadro extends StatelessWidget {
  const _Quadro({required this.linhas});

  final List<_Linha> linhas;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoresApp.contorno),
      ),
      child: Column(
        children: [
          for (var i = 0; i < linhas.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: CoresApp.contorno),
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
  });

  final IconData icone;
  final String rotulo;
  final Widget valor;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icone, color: CoresApp.sobreSuperficieVariante),
          const SizedBox(width: 12),
          Text(
            rotulo,
            style: estilos.titleSmall?.copyWith(
              color: CoresApp.sobreSuperficieVariante,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: DefaultTextStyle.merge(
                style: estilos.bodyLarge,
                child: valor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
