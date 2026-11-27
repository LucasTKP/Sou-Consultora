// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/a_pagar/widgets/selo_status_boleto.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';

/// Card do boleto em A pagar: marca e selo; vencimento (ou pagamento) e valor.
class CartaoBoleto extends StatelessWidget {
  const CartaoBoleto({
    super.key,
    required this.boleto,
    required this.hoje,
    required this.onTap,
  });

  final ResumoBoleto boleto;
  final DateTime hoje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final status = boleto.status(hoje: hoje);
    final atrasado = status == StatusBoleto.atrasado;
    final textos = textosDe(boleto, hoje: hoje);
    return Semantics(
      button: true,
      label: 'Boleto ${boleto.fornecedorNome}',
      child: Material(
        color: CoresApp.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: atrasado
                ? CoresApp.perigo.withOpacity(0.35)
                : CoresApp.contorno,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    AvatarApp(
                      iniciais: boleto.iniciais,
                      tamanho: TamanhoAvatar.card,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        boleto.fornecedorNome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: estilos.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SeloStatusBoleto(status: status),
                  ],
                ),
                const Divider(height: 24, color: CoresApp.contorno),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _Coluna(
                        rotulo: textos.rotuloData,
                        texto: textos.data,
                        cor: atrasado ? CoresApp.perigo : null,
                      ),
                    ),
                    _Coluna(
                      rotulo: textos.rotuloValor,
                      texto: FormatadorMoeda.formatar(boleto.valor),
                      cor: _corValor(status),
                      destaque: true,
                      aDireita: true,
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: CoresApp.primaria,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _corValor(StatusBoleto status) => switch (status) {
    StatusBoleto.pago => CoresApp.sucesso,
    StatusBoleto.atrasado => CoresApp.perigo,
    _ => CoresApp.primaria,
  };

  /// Textos do card conforme a situação, só data e valor (nada no meio):
  /// - vence hoje: "Vencimento" / "Hoje (12/11/2024)" / "Valor a pagar";
  /// - pendente: "Vencimento" / "18/11/2024" / "Valor a pagar";
  /// - atrasado: "Venceu em" / "05/11/2024" / "Valor original";
  /// - pago: "Liquidado em" / "01/11/2024" / "Valor liquidado".
  static ({String rotuloData, String data, String rotuloValor}) textosDe(
    ResumoBoleto boleto, {
    required DateTime hoje,
  }) {
    final vencimento = FormatadorData.curta(boleto.vencimento);
    return switch (boleto.status(hoje: hoje)) {
      StatusBoleto.pago => (
        rotuloData: 'Liquidado em',
        data: FormatadorData.curta(boleto.dataPagamento!),
        rotuloValor: 'Valor liquidado',
      ),
      StatusBoleto.atrasado => (
        rotuloData: 'Venceu em',
        data: vencimento,
        rotuloValor: 'Valor original',
      ),
      StatusBoleto.venceHoje => (
        rotuloData: 'Vencimento',
        data: 'Hoje ($vencimento)',
        rotuloValor: 'Valor a pagar',
      ),
      StatusBoleto.pendente => (
        rotuloData: 'Vencimento',
        data: vencimento,
        rotuloValor: 'Valor a pagar',
      ),
    };
  }
}

class _Coluna extends StatelessWidget {
  const _Coluna({
    required this.rotulo,
    required this.texto,
    this.cor,
    this.destaque = false,
    this.aDireita = false,
  });

  final String rotulo;
  final String texto;
  final Color? cor;
  final bool destaque;
  final bool aDireita;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: aDireita
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: estilos.bodySmall?.copyWith(
            color: cor ?? CoresApp.sobreSuperficieVariante,
          ),
        ),
        Text(
          texto,
          style: (destaque ? estilos.titleLarge : estilos.bodyLarge)?.copyWith(
            color: cor,
          ),
        ),
      ],
    );
  }
}
