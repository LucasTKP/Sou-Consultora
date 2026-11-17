import 'package:flutter/widgets.dart';
import 'package:sou_consultora/core/model/resumo_cliente.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';

/// Selo de situação da cliente (lista e detalhes).
class SeloSituacaoCliente extends StatelessWidget {
  const SeloSituacaoCliente({
    super.key,
    required this.cliente,
    required this.hoje,
  });

  final ResumoCliente cliente;
  final DateTime hoje;

  @override
  Widget build(BuildContext context) {
    final (rotulo, status) = switch (cliente.situacao(hoje)) {
      SituacaoCliente.atrasada => (
        'Deve ${FormatadorMoeda.formatar(cliente.valorAtrasado)}',
        StatusSelo.perigo,
      ),
      SituacaoCliente.venceHoje => (
        'Vence hoje ${FormatadorMoeda.formatar(cliente.valorVenceHoje)}',
        StatusSelo.alerta,
      ),
      SituacaoCliente.aniversario => ('Aniversário', StatusSelo.alerta),
      SituacaoCliente.emDia => ('Em dia', StatusSelo.sucesso),
    };
    return SeloStatusApp(rotulo: rotulo, status: status);
  }
}
