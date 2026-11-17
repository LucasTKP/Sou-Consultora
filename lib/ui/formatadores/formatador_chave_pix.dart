import 'package:sou_consultora/core/model/chave_pix.dart';
import 'package:sou_consultora/ui/formatadores/formatador_telefone.dart';

/// Exibição da chave Pix conforme o tipo.
abstract final class FormatadorChavePix {
  static String formatar(ChavePix chave) {
    return switch (chave.tipo) {
      TipoChavePix.telefone => FormatadorTelefone.formatar(chave.valorSemDdi),
      TipoChavePix.cpf => _cpf(chave.valor),
      TipoChavePix.email || TipoChavePix.aleatoria => chave.valor,
    };
  }

  /// 12345678909 → 123.456.789-09
  static String _cpf(String digitos) {
    if (digitos.length != 11) return digitos;
    return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.${digitos.substring(6, 9)}-${digitos.substring(9)}';
  }
}
