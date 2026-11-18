import 'package:sou_consultora/core/model/chave_pix.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/ui/formatadores/formatador_chave_pix.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';

/// Mensagem do "Cobrar no WhatsApp" (Vendas e A receber).
abstract final class MensagemCobranca {
  /// Oi, Carla! … parcela 2 de 2 da sua compra #0012, no valor de R$ 120,00,
  /// com vencimento em 15/11/2026. [Pix] Obrigada! 💖 Ana
  static String montar({
    required ResumoParcela parcela,
    required String nomeConsultora,
    ChavePix? chavePix,
  }) {
    final primeiroNome = parcela.clienteNome.trim().split(RegExp(r'\s+')).first;
    final codigo = '#${parcela.vendaCodigo.toString().padLeft(4, '0')}';
    final texto = StringBuffer()
      ..writeln('Oi, $primeiroNome! Tudo bem? 😊')
      ..writeln(
        'Passando para lembrar da parcela ${parcela.textoNumero} '
        'da sua compra $codigo, no valor de '
        '${FormatadorMoeda.formatar(parcela.saldo)}, '
        'com vencimento em ${FormatadorData.curta(parcela.vencimento)}.',
      );
    if (chavePix != null) {
      texto
        ..writeln()
        ..writeln('Se preferir, pode pagar pelo Pix:')
        ..writeln(FormatadorChavePix.formatar(chavePix));
    }
    texto
      ..writeln()
      ..write('Obrigada! 💖 $nomeConsultora');
    return texto.toString().replaceAll(' ', ' ');
  }
}
