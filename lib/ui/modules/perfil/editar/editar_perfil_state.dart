import 'package:sou_consultora/core/model/chave_pix.dart';

/// Formulário de edição do perfil.
class EditarPerfilState {
  const EditarPerfilState({
    required this.nome,
    required this.whatsapp,
    this.tipoPix,
    this.chavePix = '',
    this.erroNome,
    this.erroWhatsapp,
    this.erroTipoPix,
    this.erroChavePix,
    this.salvando = false,
    this.salvo = false,
    this.erroGeral,
  });

  final String nome;
  final String whatsapp;
  final TipoChavePix? tipoPix;
  final String chavePix;
  final String? erroNome;
  final String? erroWhatsapp;
  final String? erroTipoPix;
  final String? erroChavePix;
  final bool salvando;

  /// Gravou com sucesso: a tela fecha.
  final bool salvo;
  final String? erroGeral;

  EditarPerfilState copyWith({
    String? nome,
    String? whatsapp,
    TipoChavePix? Function()? tipoPix,
    String? chavePix,
    String? Function()? erroNome,
    String? Function()? erroWhatsapp,
    String? Function()? erroTipoPix,
    String? Function()? erroChavePix,
    bool? salvando,
    bool? salvo,
    String? Function()? erroGeral,
  }) {
    return EditarPerfilState(
      nome: nome ?? this.nome,
      whatsapp: whatsapp ?? this.whatsapp,
      tipoPix: tipoPix != null ? tipoPix() : this.tipoPix,
      chavePix: chavePix ?? this.chavePix,
      erroNome: erroNome != null ? erroNome() : this.erroNome,
      erroWhatsapp: erroWhatsapp != null ? erroWhatsapp() : this.erroWhatsapp,
      erroTipoPix: erroTipoPix != null ? erroTipoPix() : this.erroTipoPix,
      erroChavePix: erroChavePix != null ? erroChavePix() : this.erroChavePix,
      salvando: salvando ?? this.salvando,
      salvo: salvo ?? this.salvo,
      erroGeral: erroGeral != null ? erroGeral() : this.erroGeral,
    );
  }
}
