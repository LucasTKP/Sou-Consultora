import 'package:sou_consultora/core/model/item_venda.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/core/model/venda.dart';

/// Venda completa: resumo, itens e parcelas.
class DetalheVenda {
  const DetalheVenda({
    required this.venda,
    required this.itens,
    required this.parcelas,
  });

  final ResumoVenda venda;
  final List<ItemVendido> itens;
  final List<ResumoParcela> parcelas;

  /// Próxima parcela com saldo (a que se cobra), ou null se quitada.
  ResumoParcela? get proximaEmAberto {
    for (final parcela in parcelas) {
      if (!parcela.paga) return parcela;
    }
    return null;
  }
}

/// Compras de uma cliente: vendas e parcelas (para atrasado/pendente/pago).
class ComprasCliente {
  const ComprasCliente({required this.vendas, required this.parcelas});

  final List<ResumoVenda> vendas;
  final List<ResumoParcela> parcelas;

  int get totalGasto => vendas.fold(0, (soma, v) => soma + v.total);

  /// Atrasado (saldo vencido), pendente (saldo a vencer) e pago, com a
  /// quantidade de parcelas de cada.
  ResumoCompras resumo({required DateTime hoje}) {
    var atrasado = 0, qtdAtrasadas = 0;
    var pendente = 0, qtdPendentes = 0;
    var pago = 0, qtdPagas = 0;
    for (final parcela in parcelas) {
      pago += parcela.valorPago;
      switch (parcela.status(hoje: hoje)) {
        case StatusParcela.pago:
          qtdPagas++;
        case StatusParcela.atrasada:
          atrasado += parcela.saldo;
          qtdAtrasadas++;
        case StatusParcela.parcial || StatusParcela.aReceber:
          pendente += parcela.saldo;
          qtdPendentes++;
      }
    }
    return ResumoCompras(
      atrasado: atrasado,
      qtdAtrasadas: qtdAtrasadas,
      pendente: pendente,
      qtdPendentes: qtdPendentes,
      pago: pago,
      qtdPagas: qtdPagas,
    );
  }
}

/// Totais das compras de uma cliente (centavos).
class ResumoCompras {
  const ResumoCompras({
    required this.atrasado,
    required this.qtdAtrasadas,
    required this.pendente,
    required this.qtdPendentes,
    required this.pago,
    required this.qtdPagas,
  });

  final int atrasado;
  final int qtdAtrasadas;
  final int pendente;
  final int qtdPendentes;
  final int pago;
  final int qtdPagas;
}
