import 'package:sou_consultora/core/model/texto_busca.dart';

/// Status exibido no selo do fornecedor, em ordem de prioridade.
enum StatusFornecedor { venceHoje, emEspera, ativo }

/// Fornecedor com os números dos boletos da view `resumo_fornecedores`.
/// Valores em centavos. "Em aberto" inclui os atrasados.
class ResumoFornecedor {
  const ResumoFornecedor({
    required this.id,
    required this.nome,
    required this.criadoEm,
    this.ramo,
    this.contato,
    this.telefone,
    this.observacoes,
    this.ativo = true,
    this.qtdEmAberto = 0,
    this.valorEmAberto = 0,
    this.qtdAtrasados = 0,
    this.valorAtrasado = 0,
    this.qtdVenceHoje = 0,
    this.qtdPagos = 0,
    this.valorPagos = 0,
  });

  final String id;
  final String nome;
  final DateTime criadoEm;
  final String? ramo;
  final String? contato;

  /// Só dígitos (DDD + número).
  final String? telefone;
  final String? observacoes;
  final bool ativo;
  final int qtdEmAberto;
  final int valorEmAberto;
  final int qtdAtrasados;
  final int valorAtrasado;
  final int qtdVenceHoje;
  final int qtdPagos;
  final int valorPagos;

  bool get emEspera => !ativo;

  bool get venceHoje => qtdVenceHoje > 0;

  /// Vence hoje → em espera → ativo.
  StatusFornecedor get status {
    if (venceHoje) return StatusFornecedor.venceHoje;
    if (emEspera) return StatusFornecedor.emEspera;
    return StatusFornecedor.ativo;
  }

  String get iniciais => iniciaisDe(nome);

  bool combinaBusca(String busca) => TextoBusca.contem(nome, busca);

  /// "Nenhum boleto em aberto", "1 boleto em aberto", "2 boletos em aberto".
  String get textoBoletosEmAberto => switch (qtdEmAberto) {
    0 => 'Nenhum boleto em aberto',
    1 => '1 boleto em aberto',
    final n => '$n boletos em aberto',
  };

  /// Marca de uma palavra → 3 primeiras letras ("Natura" → "NAT");
  /// várias palavras → a inicial de até 3 delas ("O Boticário" → "OB",
  /// "Avon / Eudora" → "AE").
  static String iniciaisDe(String nome) {
    final palavras = nome
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((palavra) => palavra.isNotEmpty)
        .toList();
    if (palavras.isEmpty) return '?';
    if (palavras.length == 1) {
      final palavra = palavras.first;
      return palavra.substring(0, palavra.length.clamp(0, 3)).toUpperCase();
    }
    return palavras.take(3).map((palavra) => palavra[0]).join().toUpperCase();
  }
}
