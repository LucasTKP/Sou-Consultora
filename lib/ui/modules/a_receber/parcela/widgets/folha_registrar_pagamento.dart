// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/model/forma_pagamento.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/a_receber/parcela/a_receber_parcela_cubit.dart';
import 'package:sou_consultora/ui/modules/a_receber/parcela/a_receber_parcela_state.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/alternador_segmentado_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/area_texto_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_data_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';

/// Folha "Registrar pagamento": valor (começa no saldo, editável para
/// parcial), forma, data (hoje) e observação. Devolve o id do pagamento
/// gravado (null ao fechar sem gravar).
abstract final class FolhaRegistrarPagamento {
  static Future<String?> mostrar(
    BuildContext context, {
    required AReceberParcelaCubit cubit,
    required int saldo,
    required DateTime hoje,
  }) {
    cubit.prepararPagamento();
    return FolhaInferiorApp.mostrar<String>(
      context: context,
      titulo: 'Registrar pagamento',
      subtitulo: 'Saldo da parcela: ${FormatadorMoeda.formatar(saldo)}',
      conteudo: (_) => BlocProvider.value(
        value: cubit,
        child: _ConteudoFolha(saldo: saldo, hoje: hoje),
      ),
    );
  }
}

class _ConteudoFolha extends StatefulWidget {
  const _ConteudoFolha({required this.saldo, required this.hoje});

  final int saldo;
  final DateTime hoje;

  @override
  State<_ConteudoFolha> createState() => _ConteudoFolhaState();
}

class _ConteudoFolhaState extends State<_ConteudoFolha> {
  late int _valor = widget.saldo;
  FormaPagamento _forma = FormaPagamento.pix;
  late DateTime _data = DateTime(
    widget.hoje.year,
    widget.hoje.month,
    widget.hoje.day,
  );
  final _observacao = TextEditingController();

  @override
  void dispose() {
    _observacao.dispose();
    super.dispose();
  }

  void _alterarValor(int centavos) => setState(() => _valor = centavos);

  void _alterarForma(FormaPagamento forma) => setState(() => _forma = forma);

  void _alterarData(DateTime data) => setState(() => _data = data);

  Future<void> _confirmar() async {
    final idPagamento = await context
        .read<AReceberParcelaCubit>()
        .registrarPagamento(
          valorCentavos: _valor,
          forma: _forma,
          data: _data,
          observacao: _observacao.text,
        );
    if (idPagamento != null && mounted) {
      Navigator.of(context).pop(idPagamento);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AReceberParcelaCubit, AReceberParcelaState>(
      builder: (context, estado) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampoMoedaApp(
            rotulo: 'Valor recebido',
            obrigatorio: true,
            centavosIniciais: widget.saldo,
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
            ultimaData: widget.hoje,
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
          if (estado.erroPagamento case final erro?) ...[
            const SizedBox(height: 12),
            Text(
              erro,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: CoresApp.perigo),
            ),
          ],
          const SizedBox(height: 24),
          BotaoApp(
            rotulo: estado.registrando ? 'Registrando...' : 'Confirmar',
            iconeInicio: const Icon(Icons.check_circle_outline_rounded),
            onPressed: estado.registrando ? null : _confirmar,
          ),
        ],
      ),
    );
  }
}
