// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/a_pagar/detalhes/a_pagar_detalhes_cubit.dart';
import 'package:sou_consultora/ui/modules/a_pagar/detalhes/a_pagar_detalhes_state.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_data_app.dart';

/// Folha "Confirmar pagamento": a data (hoje por padrão, nunca futura) e o
/// valor, que é quitado inteiro. Devolve true quando gravou.
abstract final class FolhaPagarBoleto {
  static Future<bool> mostrar(
    BuildContext context, {
    required APagarDetalhesCubit cubit,
    required int valor,
    required DateTime hoje,
  }) async {
    cubit.prepararPagamento();
    final pagou = await FolhaInferiorApp.mostrar<bool>(
      context: context,
      titulo: 'Confirmar pagamento',
      subtitulo:
          'O boleto de ${FormatadorMoeda.formatar(valor)} é quitado inteiro.',
      conteudo: (_) => BlocProvider.value(
        value: cubit,
        child: _ConteudoFolha(hoje: hoje),
      ),
    );
    return pagou ?? false;
  }
}

class _ConteudoFolha extends StatefulWidget {
  const _ConteudoFolha({required this.hoje});

  final DateTime hoje;

  @override
  State<_ConteudoFolha> createState() => _ConteudoFolhaState();
}

class _ConteudoFolhaState extends State<_ConteudoFolha> {
  late DateTime _data = DateTime(
    widget.hoje.year,
    widget.hoje.month,
    widget.hoje.day,
  );

  void _alterarData(DateTime data) => setState(() => _data = data);

  Future<void> _confirmar() async {
    final pagou = await context.read<APagarDetalhesCubit>().pagar(_data);
    if (pagou && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<APagarDetalhesCubit, APagarDetalhesState>(
      builder: (context, estado) {
        final pagando = estado.acao == AcaoBoleto.pagando;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoDataApp(
              rotulo: 'Data do pagamento',
              obrigatorio: true,
              data: _data,
              ultimaData: widget.hoje,
              erro: estado.erroDataPagamento,
              onChanged: _alterarData,
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
              rotulo: pagando ? 'Confirmando...' : 'Confirmar',
              iconeInicio: const Icon(Icons.check_circle_outline_rounded),
              onPressed: pagando ? null : _confirmar,
            ),
          ],
        );
      },
    );
  }
}
