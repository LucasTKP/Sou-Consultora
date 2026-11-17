import 'package:sou_consultora/core/model/telefone.dart';

/// Tipos de chave Pix aceitos. [valorBanco] é o texto gravado em `tipo_chave_pix`.
enum TipoChavePix {
  telefone('telefone', 'Telefone'),
  cpf('cpf', 'CPF'),
  email('email', 'E-mail'),
  aleatoria('aleatoria', 'Chave aleatória');

  const TipoChavePix(this.valorBanco, this.rotulo);

  final String valorBanco;
  final String rotulo;

  static TipoChavePix? doBanco(String? valor) {
    for (final tipo in values) {
      if (tipo.valorBanco == valor) return tipo;
    }
    return null;
  }
}

/// Chave Pix já normalizada (como fica gravada no banco).
class ChavePix {
  const ChavePix({required this.tipo, required this.valor});

  /// Monta a chave a partir do que a consultora digitou. Use depois de validar.
  factory ChavePix.digitada(TipoChavePix tipo, String texto) => ChavePix(tipo: tipo, valor: normalizar(tipo, texto));

  final TipoChavePix tipo;
  final String valor;

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);

  /// Erro do campo "Tipo de chave Pix" (null = ok).
  static String? erroDoTipo(TipoChavePix? tipo, String texto) {
    if (tipo == null && texto.trim().isNotEmpty) return 'Escolha o tipo da chave';
    return null;
  }

  /// Erro do campo "Chave Pix" (null = ok). Tipo e chave vazios juntos é válido.
  static String? erroDaChave(TipoChavePix? tipo, String texto) {
    final limpo = texto.trim();
    if (tipo == null) return null;
    if (limpo.isEmpty) return 'Informe a chave Pix';
    return switch (tipo) {
      TipoChavePix.telefone => _telefoneValido(limpo) ? null : 'Telefone inválido',
      TipoChavePix.cpf => cpfValido(limpo) ? null : 'CPF inválido',
      TipoChavePix.email => _email.hasMatch(limpo) ? null : 'E-mail inválido',
      TipoChavePix.aleatoria => _uuid.hasMatch(limpo) ? null : 'Chave aleatória inválida',
    };
  }

  /// Telefone → "+55" + dígitos; CPF → 11 dígitos; e-mail e aleatória → minúsculas.
  static String normalizar(TipoChavePix tipo, String texto) {
    final limpo = texto.trim();
    return switch (tipo) {
      TipoChavePix.telefone => '+55${Telefone.digitos(_semDdi(limpo))}',
      TipoChavePix.cpf => limpo.replaceAll(RegExp(r'\D'), ''),
      TipoChavePix.email || TipoChavePix.aleatoria => limpo.toLowerCase(),
    };
  }

  /// Telefone sem o "+55" (para exibir e editar).
  String get valorSemDdi => tipo == TipoChavePix.telefone ? _semDdi(valor) : valor;

  static bool _telefoneValido(String texto) => Telefone.valido(_semDdi(texto));

  static String _semDdi(String texto) {
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    final temDdi = texto.trim().startsWith('+55') || (digitos.length > 11 && digitos.startsWith('55'));
    return temDdi ? digitos.substring(2) : digitos;
  }

  /// CPF com dígitos verificadores válidos (sequências repetidas são inválidas).
  static bool cpfValido(String texto) {
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digitos)) return false;
    final numeros = digitos.split('').map(int.parse).toList();
    return _digitoVerificador(numeros, 9) == numeros[9] && _digitoVerificador(numeros, 10) == numeros[10];
  }

  static int _digitoVerificador(List<int> numeros, int quantidade) {
    var soma = 0;
    for (var i = 0; i < quantidade; i++) {
      soma += numeros[i] * (quantidade + 1 - i);
    }
    final resto = (soma * 10) % 11;
    return resto == 10 ? 0 : resto;
  }
}
