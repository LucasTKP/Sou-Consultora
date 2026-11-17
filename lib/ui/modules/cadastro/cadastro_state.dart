/// Formulário de cadastro da consultora.
class CadastroState {
  const CadastroState({
    required this.pedirNome,
    this.nome = '',
    this.whatsapp = '',
    this.erroNome,
    this.erroWhatsapp,
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

  /// Falha ao gravar (ex.: sem internet). Exibida uma vez.
  final String? erroGeral;

  CadastroState copyWith({
    String? nome,
    String? whatsapp,
    String? Function()? erroNome,
    String? Function()? erroWhatsapp,
    bool? salvando,
    String? Function()? erroGeral,
  }) {
    return CadastroState(
      pedirNome: pedirNome,
      nome: nome ?? this.nome,
      whatsapp: whatsapp ?? this.whatsapp,
      erroNome: erroNome != null ? erroNome() : this.erroNome,
      erroWhatsapp: erroWhatsapp != null ? erroWhatsapp() : this.erroWhatsapp,
      salvando: salvando ?? this.salvando,
      erroGeral: erroGeral != null ? erroGeral() : this.erroGeral,
    );
  }
}
