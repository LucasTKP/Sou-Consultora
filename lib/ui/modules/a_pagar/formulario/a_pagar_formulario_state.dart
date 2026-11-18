import 'package:sou_consultora/core/model/forma_pagamento_boleto.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';

class APagarFormularioState {
  const APagarFormularioState({
    this.idBoleto,
    this.carregando = true,
    this.erroCarregar,
    this.passo = 1,
    this.marcas = const [],
    this.fornecedorId,
    this.fornecedorIdOriginal,
    this.valor,
    this.vencimento,
    this.forma,
    this.observacoes = '',
    this.erroMarca,
    this.erroValor,
    this.erroVencimento,
    this.salvando = false,
    this.salvo = false,
    this.aviso,
    this.versaoPreenchimento = 0,
  });

  static const totalPassos = 2;

  /// Nulo = novo boleto.
  final String? idBoleto;
  final bool carregando;
  final String? erroCarregar;

  /// 1 = dados do boleto; 2 = pagamento e lembretes.
  final int passo;

  /// Todas as marcas (o seletor mostra só [marcasDisponiveis]).
  final List<ResumoFornecedor> marcas;
  final String? fornecedorId;

  /// Marca do boleto ao abrir a edição (aparece mesmo se estiver em espera).
  final String? fornecedorIdOriginal;

  /// Centavos.
  final int? valor;
  final DateTime? vencimento;
  final FormaPagamentoBoleto? forma;
  final String observacoes;
  final String? erroMarca;
  final String? erroValor;
  final String? erroVencimento;
  final bool salvando;
  final bool salvo;
  final String? aviso;

  /// Muda quando o cubit preenche os campos (edição carregada).
  final int versaoPreenchimento;

  bool get editando => idBoleto != null;

  /// Marcas ativas, mais a marca atual do boleto se estiver em espera.
  List<ResumoFornecedor> get marcasDisponiveis => [
    for (final marca in marcas)
      if (marca.ativo || marca.id == fornecedorIdOriginal) marca,
  ];

  ResumoFornecedor? get marcaEscolhida =>
      marcas.where((m) => m.id == fornecedorId).firstOrNull;

  APagarFormularioState copyWith({
    bool? carregando,
    String? Function()? erroCarregar,
    int? passo,
    List<ResumoFornecedor>? marcas,
    String? Function()? fornecedorId,
    String? Function()? fornecedorIdOriginal,
    int? Function()? valor,
    DateTime? Function()? vencimento,
    FormaPagamentoBoleto? Function()? forma,
    String? observacoes,
    String? Function()? erroMarca,
    String? Function()? erroValor,
    String? Function()? erroVencimento,
    bool? salvando,
    bool? salvo,
    String? Function()? aviso,
    int? versaoPreenchimento,
  }) {
    return APagarFormularioState(
      idBoleto: idBoleto,
      carregando: carregando ?? this.carregando,
      erroCarregar: erroCarregar != null ? erroCarregar() : this.erroCarregar,
      passo: passo ?? this.passo,
      marcas: marcas ?? this.marcas,
      fornecedorId: fornecedorId != null ? fornecedorId() : this.fornecedorId,
      fornecedorIdOriginal: fornecedorIdOriginal != null
          ? fornecedorIdOriginal()
          : this.fornecedorIdOriginal,
      valor: valor != null ? valor() : this.valor,
      vencimento: vencimento != null ? vencimento() : this.vencimento,
      forma: forma != null ? forma() : this.forma,
      observacoes: observacoes ?? this.observacoes,
      erroMarca: erroMarca != null ? erroMarca() : this.erroMarca,
      erroValor: erroValor != null ? erroValor() : this.erroValor,
      erroVencimento: erroVencimento != null
          ? erroVencimento()
          : this.erroVencimento,
      salvando: salvando ?? this.salvando,
      salvo: salvo ?? this.salvo,
      aviso: aviso != null ? aviso() : this.aviso,
      versaoPreenchimento: versaoPreenchimento ?? this.versaoPreenchimento,
    );
  }
}
