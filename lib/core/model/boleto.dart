import 'package:sou_consultora/core/model/forma_pagamento_boleto.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';

/// Situação de um boleto, calculada (nunca gravada).
enum StatusBoleto {
  pendente('Pendente'),
  venceHoje('Vence hoje'),
  atrasado('Atrasado'),
  pago('Pago');

  const StatusBoleto(this.rotulo);

  final String rotulo;
}

/// Um boleto com o nome da marca (view `resumo_boletos`). Valor em centavos.
class ResumoBoleto {
  const ResumoBoleto({
    required this.id,
    required this.fornecedorId,
    required this.fornecedorNome,
    required this.valor,
    required this.vencimento,
    this.fornecedorAtivo = true,
    this.forma,
    this.observacoes,
    this.caminhoComprovante,
    this.dataPagamento,
  });

  final String id;
  final String fornecedorId;
  final String fornecedorNome;
  final bool fornecedorAtivo;
  final int valor;
  final DateTime vencimento;
  final FormaPagamentoBoleto? forma;
  final String? observacoes;

  /// Caminho no bucket `comprovantes` (`<id>/boletos/<boleto>/<momento>.pdf`).
  final String? caminhoComprovante;

  /// Preenchida = pago (sempre o valor inteiro).
  final DateTime? dataPagamento;

  bool get pago => dataPagamento != null;

  bool get temComprovante => caminhoComprovante != null;

  bool get comprovanteEmPdf =>
      caminhoComprovante?.toLowerCase().endsWith('.pdf') ?? false;

  String get iniciais => ResumoFornecedor.iniciaisDe(fornecedorNome);

  /// Pago → atrasado (vencido) → vence hoje → pendente.
  StatusBoleto status({required DateTime hoje}) {
    if (pago) return StatusBoleto.pago;
    final dia = _dia(vencimento);
    final hojeDia = _dia(hoje);
    if (dia.isBefore(hojeDia)) return StatusBoleto.atrasado;
    if (dia == hojeDia) return StatusBoleto.venceHoje;
    return StatusBoleto.pendente;
  }

  /// Dias desde o vencimento (0 se ainda não venceu).
  int diasAtraso({required DateTime hoje}) {
    final dias = _dia(hoje).difference(_dia(vencimento)).inDays;
    return dias < 0 ? 0 : dias;
  }

  /// Dias até o vencimento (0 se já venceu ou vence hoje).
  int diasParaVencer({required DateTime hoje}) {
    final dias = _dia(vencimento).difference(_dia(hoje)).inDays;
    return dias < 0 ? 0 : dias;
  }

  /// Data do pagamento: obrigatória e nunca no futuro.
  static String? validarDataPagamento(
    DateTime? data, {
    required DateTime hoje,
  }) {
    if (data == null) return 'Informe a data do pagamento';
    return _dia(data).isAfter(_dia(hoje))
        ? 'A data do pagamento não pode ser no futuro'
        : null;
  }

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Dados de um boleto a lançar ou editar (o banco preenche o resto).
class PedidoBoleto {
  const PedidoBoleto({
    required this.fornecedorId,
    required this.valor,
    required this.vencimento,
    this.forma,
    this.observacoes,
  });

  final String fornecedorId;

  /// Centavos.
  final int valor;
  final DateTime vencimento;
  final FormaPagamentoBoleto? forma;
  final String? observacoes;

  static String? validarFornecedor(String? id) =>
      id == null ? 'Escolha a marca do boleto' : null;

  static String? validarValor(int? centavos) =>
      centavos == null || centavos <= 0 ? 'Informe o valor do boleto' : null;

  static String? validarVencimento(DateTime? data) =>
      data == null ? 'Informe a data de vencimento' : null;
}
