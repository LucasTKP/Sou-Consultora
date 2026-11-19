// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/model/forma_pagamento.dart';
import 'package:sou_consultora/core/model/pagamento.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/a_receber/parcela/a_receber_parcela_cubit.dart';
import 'package:sou_consultora/ui/modules/a_receber/parcela/a_receber_parcela_state.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/dialogo_confirmacao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';
import 'package:sou_consultora/ui/widgets/feedback/erro_em_toast.dart';
import 'package:sou_consultora/ui/widgets/formularios/alternador_segmentado_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/area_texto_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_data_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';

/// Folha "Registrar pagamento" (ou "Editar pagamento" quando [pagamento] vem
/// preenchido): valor, forma, data e observação. Devolve o id do pagamento
/// gravado ou excluído (null ao fechar sem mudar nada).
///
/// Na edição, [saldo] é o máximo que o pagamento pode chegar: o saldo da
/// parcela mais o que ele já ocupa.
abstract final class FolhaRegistrarPagamento {
  static Future<String?> mostrar(
    BuildContext context, {
    required AReceberParcelaCubit cubit,
    required int saldo,
    required DateTime hoje,
    Pagamento? pagamento,
  }) {
    cubit.prepararPagamento();
    return FolhaInferiorApp.mostrar<String>(
      context: context,
      titulo: pagamento == null ? 'Registrar pagamento' : 'Editar pagamento',
      subtitulo: pagamento == null
          ? 'Saldo da parcela: ${FormatadorMoeda.formatar(saldo)}'
          : 'Valor até ${FormatadorMoeda.formatar(saldo)}',
      conteudo: (_) => BlocProvider.value(
        value: cubit,
        child: _ConteudoFolha(saldo: saldo, hoje: hoje, pagamento: pagamento),
      ),
    );
  }
}

class _ConteudoFolha extends StatefulWidget {
  const _ConteudoFolha({
    required this.saldo,
    required this.hoje,
    this.pagamento,
  });

  final int saldo;
  final DateTime hoje;
  final Pagamento? pagamento;

  @override
  State<_ConteudoFolha> createState() => _ConteudoFolhaState();
}

class _ConteudoFolhaState extends State<_ConteudoFolha> {
  late int _valor = widget.pagamento?.valor ?? widget.saldo;
  late FormaPagamento _forma = widget.pagamento?.forma ?? FormaPagamento.pix;
  late DateTime _data = _diaDe(widget.pagamento?.data ?? widget.hoje);
  late final _observacao = TextEditingController(
    text: widget.pagamento?.observacao ?? '',
  );

  static DateTime _diaDe(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  @override
  void dispose() {
    _observacao.dispose();
    super.dispose();
  }

  void _alterarValor(int centavos) => setState(() => _valor = centavos);

  void _alterarForma(FormaPagamento forma) => setState(() => _forma = forma);

  void _alterarData(DateTime data) => setState(() => _data = data);

  Future<void> _confirmar() async {
    final cubit = context.read<AReceberParcelaCubit>();
    final pagamento = widget.pagamento;
    final String? id;
    if (pagamento == null) {
      id = await cubit.registrarPagamento(
        valorCentavos: _valor,
        forma: _forma,
        data: _data,
        observacao: _observacao.text,
      );
    } else {
      final gravou = await cubit.editarPagamento(
        pagamentoId: pagamento.id,
        valorCentavos: _valor,
        forma: _forma,
        data: _data,
        observacao: _observacao.text,
      );
      id = gravou ? pagamento.id : null;
    }
    if (id != null && mounted) {
      Navigator.of(context).pop(id);
    }
  }

  Future<void> _excluir() async {
    final pagamento = widget.pagamento;
    if (pagamento == null) return;
    final confirmou = await DialogoConfirmacaoApp.mostrar(
      context: context,
      titulo: 'Excluir este pagamento?',
      mensagem: 'O valor volta ao saldo da parcela. Não dá para desfazer.',
      rotuloConfirmar: 'Excluir',
      perigo: true,
    );
    if (!confirmou || !mounted) return;
    final excluiu = await context.read<AReceberParcelaCubit>().excluirPagamento(
      pagamento.id,
    );
    if (excluiu && mounted) {
      Navigator.of(context).pop(pagamento.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.pagamento != null;
    return BlocBuilder<AReceberParcelaCubit, AReceberParcelaState>(
      builder: (context, estado) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampoMoedaApp(
            rotulo: 'Valor recebido',
            obrigatorio: true,
            centavosIniciais: _valor,
            erro: estado.erroValor,
            habilitado: !estado.registrando,
            onChanged: _alterarValor,
          ),
          const SizedBox(height: 16),
          Text(
            'Forma de pagamento',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          AlternadorSegmentadoApp<FormaPagamento>(
            opcoes: [
              for (final forma in FormaPagamento.values)
                OpcaoSegmento(valor: forma, rotulo: forma.rotulo),
            ],
            selecionado: _forma,
            onChanged: _alterarForma,
          ),
          const SizedBox(height: 16),
          CampoDataApp(
            rotulo: 'Data do pagamento',
            obrigatorio: true,
            data: _data,
            erro: estado.erroData,
            onChanged: _alterarData,
          ),
          const SizedBox(height: 16),
          AreaTextoApp(
            rotulo: 'Observação',
            opcional: true,
            placeholder: 'Ex.: pagou metade, o resto no dia 30',
            controller: _observacao,
            habilitado: !estado.registrando,
            linhas: 2,
          ),
          ErroEmToast(erro: estado.erroPagamento),
          const SizedBox(height: 24),
          BotaoApp(
            rotulo: estado.registrando
                ? 'Salvando...'
                : editando
                ? 'Salvar pagamento'
                : 'Confirmar',
            onPressed: estado.registrando ? null : _confirmar,
          ),
          if (editando) ...[
            const SizedBox(height: 12),
            BotaoApp.perigo(
              rotulo: 'Excluir pagamento',
              onPressed: estado.registrando ? null : _excluir,
            ),
          ],
        ],
      ),
    );
  }
}
