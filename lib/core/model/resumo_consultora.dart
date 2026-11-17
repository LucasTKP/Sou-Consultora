import 'package:sou_consultora/core/model/consultora.dart';

/// Dados mínimos da consultora para cabeçalhos e menu (nome, foto, iniciais).
class ResumoConsultora {
  const ResumoConsultora({required this.nome, this.fotoUrl});

  /// Monta o resumo a partir do que estiver disponível, na ordem:
  /// nome completo → e-mail → texto vazio.
  factory ResumoConsultora.de({String? nome, String? email, String? fotoUrl}) {
    final nomeLimpo = nome?.trim() ?? '';
    final nomeFinal = nomeLimpo.isNotEmpty ? nomeLimpo : (email?.trim() ?? '');
    final fotoLimpa = fotoUrl?.trim() ?? '';
    return ResumoConsultora(
      nome: nomeFinal,
      fotoUrl: fotoLimpa.isEmpty ? null : fotoLimpa,
    );
  }

  factory ResumoConsultora.daConsultora(Consultora consultora) {
    return ResumoConsultora.de(
      nome: consultora.nome,
      fotoUrl: consultora.urlFoto,
    );
  }

  final String nome;
  final String? fotoUrl;

  bool get temFoto => fotoUrl != null;

  /// Até duas letras: primeira do primeiro nome + primeira do último.
  /// Sem nome utilizável → "?".
  String get iniciais {
    final partes = nome
        .split(RegExp(r'[\s@._-]+'))
        .where(
          (parte) =>
              parte.isNotEmpty && RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(parte[0]),
        )
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }
}
