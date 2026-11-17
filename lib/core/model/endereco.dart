/// Endereço de entrega (tabela `enderecos`). Todos os campos são opcionais no banco.
class Endereco {
  const Endereco({
    this.cep,
    this.rua,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.uf,
    this.referencia,
  });

  /// CEP só com dígitos.
  final String? cep;
  final String? rua;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cidade;

  /// Duas letras maiúsculas (ex.: "SP").
  final String? uf;
  final String? referencia;

  static const ufs = [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PR',
    'PB',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO',
  ];

  List<String?> get _campos => [
    cep,
    rua,
    numero,
    complemento,
    bairro,
    cidade,
    uf,
    referencia,
  ];

  /// Nenhum campo preenchido (o mesmo que "sem endereço").
  bool get vazio => _campos.every(_embranco);

  /// "Rua das Acácias, 450 - Apto 82" (null sem rua).
  String? get linhaRua {
    if (_embranco(rua)) return null;
    final comNumero = _embranco(numero)
        ? rua!.trim()
        : '${rua!.trim()}, ${numero!.trim()}';
    return _embranco(complemento)
        ? comNumero
        : '$comNumero - ${complemento!.trim()}';
  }

  /// "Jd. Paulista - SP", "Jd. Paulista, São Paulo - SP"... (null sem nenhum dos três).
  String? get linhaBairroCidade {
    final lugar = [bairro, cidade]
        .where((parte) => !_embranco(parte))
        .map((parte) => parte!.trim())
        .join(', ');
    final estado = _embranco(uf) ? '' : uf!.trim();
    if (lugar.isEmpty) return estado.isEmpty ? null : estado;
    return estado.isEmpty ? lugar : '$lugar - $estado';
  }

  /// Erros por campo. Endereço vazio é válido; com qualquer campo, rua e número são obrigatórios.
  ({String? rua, String? numero, String? cep}) validar() {
    if (vazio) return (rua: null, numero: null, cep: null);
    final digitosCep = (cep ?? '').replaceAll(RegExp(r'\D'), '');
    return (
      rua: _embranco(rua) ? 'Obrigatório' : null,
      numero: _embranco(numero) ? 'Obrigatório' : null,
      cep: digitosCep.isEmpty || digitosCep.length == 8 ? null : 'CEP inválido',
    );
  }

  /// Dados para a RPC `salvar_cliente` (null quando vazio).
  Map<String, String?>? paraGravar() {
    if (vazio) return null;
    return {
      'cep': cep?.replaceAll(RegExp(r'\D'), ''),
      'rua': rua,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'uf': uf,
      'referencia': referencia,
    };
  }

  static bool _embranco(String? texto) => texto == null || texto.trim().isEmpty;
}
