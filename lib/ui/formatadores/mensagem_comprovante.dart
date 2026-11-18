import 'package:sou_consultora/core/model/detalhe_parcela.dart';
import 'package:sou_consultora/core/model/pagamento.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';

/// Texto que acompanha a imagem do comprovante ao compartilhar.
abstract final class MensagemComprovante {
  /// Comprovante de pagamento • Carla Menezes
  /// R$ 120,00 via Pix em 15/10/2026
  /// Parcela 2 de 2 • Quitada
  /// Saldo restante da venda: R$ 0,00
  static String montar({
    required DetalheParcela detalhe,
    required Pagamento pagamento,
  }) {
    final parcela = detalhe.parcela;
    final texto = StringBuffer()
      ..writeln('Comprovante de pagamento • ${parcela.clienteNome}')
      ..writeln(
        '${FormatadorMoeda.formatar(pagamento.valor)} via '
        '${pagamento.forma.rotulo} em ${FormatadorData.curta(pagamento.data)}',
      )
      ..writeln('Parcela ${parcela.textoNumero} • ${situacao(detalhe)}')
      ..write(
        'Saldo restante da venda: '
        '${FormatadorMoeda.formatar(detalhe.saldoDaVenda)}',
      );
    return texto.toString();
  }

  /// "Quitada" ou "Parcial" (situação da parcela agora).
  static String situacao(DetalheParcela detalhe) =>
      detalhe.parcela.paga ? 'Quitada' : 'Parcial';
}
