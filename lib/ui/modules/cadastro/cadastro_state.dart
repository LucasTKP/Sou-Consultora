import 'package:sou_consultora/core/model/marca_padrao.dart';

/// Formulário de cadastro da consultora.
class CadastroState {
  const CadastroState({
    required this.pedirNome,
    this.nome = '',
    this.whatsapp = '',
    this.erroNome,
    this.erroWhatsapp,
    this.aceitouTermos = false,
    this.erroTermos,
    this.marcas = const {},
    this.salvando = false,
    this.erroGeral,
  });

  /// O provedor de login não informou o nome: a tela pede.
  final bool pedirNome;
  final String nome;
  final String whatsapp;
  final String? erroNome;
  final String? erroWhatsapp;
  final bool salvando;
  final bool aceitouTermos;
  final String? erroTermos;

  /// Marcas que a consultora vende (viram fornecedores ao cadastrar).
  final Set<MarcaPadrao> marcas;

  /// Falha ao gravar (ex.: sem internet). Exibida uma vez.
  final String? erroGeral;

  CadastroState copyWith({
    String? nome,
    String? whatsapp,
    String? Function()? erroNome,
    String? Function()? erroWhatsapp,
    bool? aceitouTermos,
    String? Function()? erroTermos,
    Set<MarcaPadrao>? marcas,
    bool? salvando,
    String? Function()? erroGeral,
  }) {
    return CadastroState(
      pedirNome: pedirNome,
      nome: nome ?? this.nome,
      whatsapp: whatsapp ?? this.whatsapp,
      erroNome: erroNome != null ? erroNome() : this.erroNome,
      erroWhatsapp: erroWhatsapp != null ? erroWhatsapp() : this.erroWhatsapp,
      aceitouTermos: aceitouTermos ?? this.aceitouTermos,
      erroTermos: erroTermos != null ? erroTermos() : this.erroTermos,
      marcas: marcas ?? this.marcas,
      salvando: salvando ?? this.salvando,
      erroGeral: erroGeral != null ? erroGeral() : this.erroGeral,
    );
  }
}
