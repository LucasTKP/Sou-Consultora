import 'package:flutter/widgets.dart';
import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';

/// Selo da situação do boleto (lista e detalhes de A pagar).
class SeloStatusBoleto extends StatelessWidget {
  const SeloStatusBoleto({super.key, required this.status});

  final StatusBoleto status;

  @override
  Widget build(BuildContext context) {
    return SeloStatusApp(
      rotulo: status.rotulo,
      status: switch (status) {
        StatusBoleto.pago => StatusSelo.sucesso,
        StatusBoleto.atrasado => StatusSelo.perigo,
        StatusBoleto.venceHoje => StatusSelo.alerta,
        StatusBoleto.pendente => StatusSelo.neutro,
      },
    );
  }
}
