import 'package:flutter/widgets.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';

/// Selo de status do fornecedor (lista e detalhes).
class SeloStatusFornecedor extends StatelessWidget {
  const SeloStatusFornecedor({
    super.key,
    required this.fornecedor,
    this.tamanho = TamanhoSelo.cartao,
  });

  final TamanhoSelo tamanho;

  final ResumoFornecedor fornecedor;

  @override
  Widget build(BuildContext context) {
    final (rotulo, status) = switch (fornecedor.status) {
      StatusFornecedor.venceHoje => ('Vence hoje', StatusSelo.alerta),
      StatusFornecedor.emEspera => ('Em espera', StatusSelo.neutro),
      StatusFornecedor.ativo => ('Ativo', StatusSelo.sucesso),
    };
    return SeloStatusApp(rotulo: rotulo, status: status, tamanho: tamanho);
  }
}
