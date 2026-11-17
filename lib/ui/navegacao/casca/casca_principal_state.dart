import 'package:sou_consultora/core/model/resumo_consultora.dart';

/// Dados do menu lateral (nome/foto e versão) e situação da saída da conta.
class CascaPrincipalState {
  const CascaPrincipalState({
    required this.resumo,
    this.versao = '',
    this.saindo = false,
  });

  final ResumoConsultora resumo;
  final String versao;
  final bool saindo;

  CascaPrincipalState copyWith({
    ResumoConsultora? resumo,
    String? versao,
    bool? saindo,
  }) {
    return CascaPrincipalState(
      resumo: resumo ?? this.resumo,
      versao: versao ?? this.versao,
      saindo: saindo ?? this.saindo,
    );
  }
}
