import 'package:sou_consultora/core/model/pagamento.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/core/model/venda.dart';

/// Uma parcela com os pagamentos dela, as parcelas da venda e a venda.
class DetalheParcela {
  const DetalheParcela({
    required this.parcela,
    required this.pagamentos,
    required this.parcelasDaVenda,
    required this.venda,
  });

  final ResumoParcela parcela;

  /// Pagamentos desta parcela, do mais recente para o mais antigo.
  final List<Pagamento> pagamentos;
  final List<ResumoParcela> parcelasDaVenda;
  final ResumoVenda venda;

  Pagamento? get ultimoPagamento =>
      pagamentos.isEmpty ? null : pagamentos.first;

  /// O pagamento [id] desta parcela; sem id (ou se não achar), o mais recente.
  /// Um pagamento com data retroativa não é o mais recente, por isso o
  /// comprovante logo após registrar usa o id.
  Pagamento? pagamentoDoComprovante(String? id) {
    if (id == null) return ultimoPagamento;
    for (final pagamento in pagamentos) {
      if (pagamento.id == id) return pagamento;
    }
    return ultimoPagamento;
  }

  /// Quanto ainda falta da venda inteira (soma dos saldos das parcelas).
  int get saldoDaVenda =>
      parcelasDaVenda.fold(0, (total, p) => total + p.saldo);
}
