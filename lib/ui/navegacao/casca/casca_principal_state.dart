import 'package:sou_consultora/core/model/resumo_consultora.dart';

/// Dados do menu lateral: nome, foto e selo de cobranças atrasadas.
class CascaPrincipalState {
  const CascaPrincipalState({required this.resumo, this.qtdAtrasadas = 0});

  final ResumoConsultora resumo;

  /// Parcelas atrasadas (selo de A Receber no menu).
  final int qtdAtrasadas;

  CascaPrincipalState copyWith({ResumoConsultora? resumo, int? qtdAtrasadas}) {
    return CascaPrincipalState(
      resumo: resumo ?? this.resumo,
      qtdAtrasadas: qtdAtrasadas ?? this.qtdAtrasadas,
    );
  }
}
