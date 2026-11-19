import 'package:flutter/widgets.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/core/model/venda.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';

/// Selo de status da venda (lista, detalhes, compras da cliente).
class SeloStatusVenda extends StatelessWidget {
  const SeloStatusVenda({
    super.key,
    required this.status,
    this.tamanho = TamanhoSelo.cartao,
  });

  final TamanhoSelo tamanho;

  final StatusVenda status;

  @override
  Widget build(BuildContext context) {
    return SeloStatusApp(
      tamanho: tamanho,
      rotulo: status.rotulo,
      status: switch (status) {
        StatusVenda.quitada => StatusSelo.sucesso,
        StatusVenda.emAberto => StatusSelo.alerta,
        StatusVenda.atrasada => StatusSelo.perigo,
      },
    );
  }
}

/// Selo de status da parcela (Vendas e A receber).
class SeloStatusParcela extends StatelessWidget {
  const SeloStatusParcela({
    super.key,
    required this.status,
    this.tamanho = TamanhoSelo.cartao,
  });

  final TamanhoSelo tamanho;

  final StatusParcela status;

  @override
  Widget build(BuildContext context) {
    return SeloStatusApp(
      tamanho: tamanho,
      rotulo: status.rotulo,
      status: switch (status) {
        StatusParcela.pago => StatusSelo.sucesso,
        StatusParcela.parcial => StatusSelo.primario,
        StatusParcela.aReceber => StatusSelo.alerta,
        StatusParcela.atrasada => StatusSelo.perigo,
      },
    );
  }
}
