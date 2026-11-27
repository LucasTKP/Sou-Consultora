import 'package:sou_consultora/core/model/telefone.dart';

/// Dados editáveis de um fornecedor (marca), já normalizados para gravar:
/// textos opcionais vazios viram `null` e o telefone fica só com dígitos.
class Fornecedor {
  Fornecedor({
    required String nome,
    String? ramo,
    String? contato,
    String? telefone,
    String? observacoes,
    this.ativo = true,
  }) : nome = nome.trim(),
       ramo = _textoOuNulo(ramo),
       contato = _textoOuNulo(contato),
       telefone = _telefoneOuNulo(telefone),
       observacoes = _textoOuNulo(observacoes);

  final String nome;
  final String? ramo;
  final String? contato;

  /// Só dígitos (DDD + número) ou `null`.
  final String? telefone;
  final String? observacoes;

  /// `false` = em espera.
  final bool ativo;

  static const mensagemDuplicado = 'Já existe um fornecedor com esse nome.';

  static String? validarNome(String texto) =>
      texto.trim().isEmpty ? 'Informe o nome do fornecedor' : null;

  /// Telefone é opcional; se informado, precisa ter DDD + 8 ou 9 dígitos.
  static String? validarTelefone(String texto) {
    if (texto.trim().isEmpty) return null;
    return Telefone.valido(texto) ? null : 'Telefone incompleto';
  }

  static String? _textoOuNulo(String? texto) {
    final limpo = texto?.trim() ?? '';
    return limpo.isEmpty ? null : limpo;
  }

  static String? _telefoneOuNulo(String? texto) {
    final digitos = Telefone.digitos(texto ?? '');
    return digitos.isEmpty ? null : digitos;
  }
}
