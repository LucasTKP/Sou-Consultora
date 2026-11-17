// ignore_for_file: deprecated_member_use
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:flutter/material.dart';

/// Extensão de tema para badges/status (fora do ColorScheme padrão).
@immutable
class CoresStatusApp extends ThemeExtension<CoresStatusApp> {
  const CoresStatusApp({
    required this.sucesso,
    required this.sucessoContainer,
    required this.alerta,
    required this.alertaContainer,
    required this.perigo,
    required this.perigoContainer,
    required this.neutro,
    required this.neutroContainer,
  });

  final Color sucesso;
  final Color sucessoContainer;
  final Color alerta;
  final Color alertaContainer;
  final Color perigo;
  final Color perigoContainer;
  final Color neutro;
  final Color neutroContainer;

  static const CoresStatusApp claro = CoresStatusApp(
    sucesso: CoresApp.sucesso,
    sucessoContainer: CoresApp.sucessoContainer,
    alerta: CoresApp.alerta,
    alertaContainer: CoresApp.alertaContainer,
    perigo: CoresApp.perigo,
    perigoContainer: CoresApp.perigoContainer,
    neutro: CoresApp.neutro,
    neutroContainer: CoresApp.neutroContainer,
  );

  static CoresStatusApp de(BuildContext context) {
    return Theme.of(context).extension<CoresStatusApp>() ?? claro;
  }

  @override
  CoresStatusApp copyWith({
    Color? sucesso,
    Color? sucessoContainer,
    Color? alerta,
    Color? alertaContainer,
    Color? perigo,
    Color? perigoContainer,
    Color? neutro,
    Color? neutroContainer,
  }) {
    return CoresStatusApp(
      sucesso: sucesso ?? this.sucesso,
      sucessoContainer: sucessoContainer ?? this.sucessoContainer,
      alerta: alerta ?? this.alerta,
      alertaContainer: alertaContainer ?? this.alertaContainer,
      perigo: perigo ?? this.perigo,
      perigoContainer: perigoContainer ?? this.perigoContainer,
      neutro: neutro ?? this.neutro,
      neutroContainer: neutroContainer ?? this.neutroContainer,
    );
  }

  @override
  CoresStatusApp lerp(ThemeExtension<CoresStatusApp>? other, double t) {
    if (other is! CoresStatusApp) return this;
    return CoresStatusApp(
      sucesso: Color.lerp(sucesso, other.sucesso, t)!,
      sucessoContainer: Color.lerp(
        sucessoContainer,
        other.sucessoContainer,
        t,
      )!,
      alerta: Color.lerp(alerta, other.alerta, t)!,
      alertaContainer: Color.lerp(alertaContainer, other.alertaContainer, t)!,
      perigo: Color.lerp(perigo, other.perigo, t)!,
      perigoContainer: Color.lerp(perigoContainer, other.perigoContainer, t)!,
      neutro: Color.lerp(neutro, other.neutro, t)!,
      neutroContainer: Color.lerp(neutroContainer, other.neutroContainer, t)!,
    );
  }
}
