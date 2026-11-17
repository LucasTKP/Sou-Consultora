class FornecedoresFormularioState {
  const FornecedoresFormularioState({
    this.idFornecedor,
    this.carregando = false,
    this.erroCarregar,
    this.nome = '',
    this.ramo = '',
    this.contato = '',
    this.telefone = '',
    this.observacoes = '',
    this.emEspera = false,
    this.erroNome,
    this.erroTelefone,
    this.salvando = false,
    this.salvo = false,
    this.aviso,
    this.versaoPreenchimento = 0,
  });

  /// Nulo = novo fornecedor.
  final String? idFornecedor;
  final bool carregando;
  final String? erroCarregar;
  final String nome;
  final String ramo;
  final String contato;

  /// Como digitado, com máscara.
  final String telefone;
  final String observacoes;
  final bool emEspera;
  final String? erroNome;
  final String? erroTelefone;
  final bool salvando;
  final bool salvo;

  /// Mensagem passageira (falha ao salvar, nome repetido).
  final String? aviso;

  /// Muda quando o cubit preenche os campos (edição carregada).
  final int versaoPreenchimento;

  bool get editando => idFornecedor != null;

  FornecedoresFormularioState copyWith({
    bool? carregando,
    String? Function()? erroCarregar,
    String? nome,
    String? ramo,
    String? contato,
    String? telefone,
    String? observacoes,
    bool? emEspera,
    String? Function()? erroNome,
    String? Function()? erroTelefone,
    bool? salvando,
    bool? salvo,
    String? Function()? aviso,
    int? versaoPreenchimento,
  }) {
    return FornecedoresFormularioState(
      idFornecedor: idFornecedor,
      carregando: carregando ?? this.carregando,
      erroCarregar: erroCarregar != null ? erroCarregar() : this.erroCarregar,
      nome: nome ?? this.nome,
      ramo: ramo ?? this.ramo,
      contato: contato ?? this.contato,
      telefone: telefone ?? this.telefone,
      observacoes: observacoes ?? this.observacoes,
      emEspera: emEspera ?? this.emEspera,
      erroNome: erroNome != null ? erroNome() : this.erroNome,
      erroTelefone: erroTelefone != null ? erroTelefone() : this.erroTelefone,
      salvando: salvando ?? this.salvando,
      salvo: salvo ?? this.salvo,
      aviso: aviso != null ? aviso() : this.aviso,
      versaoPreenchimento: versaoPreenchimento ?? this.versaoPreenchimento,
    );
  }
}
