import 'package:sou_consultora/core/model/chave_pix.dart';
import 'package:sou_consultora/core/model/telefone.dart';

/// Consultora logada (registro de `consultoras`).
class Consultora {
  const Consultora({
    required this.id,
    required this.nome,
    required this.whatsapp,
    this.chavePix,
    this.caminhoFoto,
    this.urlFoto,
  });

  final String id;
  final String nome;

  /// Só dígitos (DDD + número).
  final String whatsapp;
  final ChavePix? chavePix;

  /// Caminho no bucket `fotos` (`<id>/perfil-....jpg`).
  final String? caminhoFoto;

  /// URL assinada temporária para exibir a foto.
  final String? urlFoto;

  bool get temChavePix => chavePix != null;

  Consultora copyWith({String? nome, String? whatsapp, String? Function()? urlFoto}) {
    return Consultora(
      id: id,
      nome: nome ?? this.nome,
      whatsapp: whatsapp ?? this.whatsapp,
      chavePix: chavePix,
      caminhoFoto: caminhoFoto,
      urlFoto: urlFoto != null ? urlFoto() : this.urlFoto,
    );
  }

  static String? validarNome(String texto) => texto.trim().isEmpty ? 'Informe o nome' : null;

  static String? validarWhatsapp(String texto) => Telefone.valido(texto) ? null : 'Informe o WhatsApp com DDD';
}
