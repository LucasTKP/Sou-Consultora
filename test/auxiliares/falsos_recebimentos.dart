import 'dart:typed_data';

import 'package:sou_consultora/core/dto/pagamento_dto.dart';
import 'package:sou_consultora/core/dto/resumo_parcela_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/forma_pagamento.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/core/repository/repositorio_recebimentos.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/core/service/servico_compartilhar.dart';
import 'package:sou_consultora/core/service/servico_recebimentos.dart';

import 'falsos_vendas.dart';

PagamentoDto pagamentoDto(
  String id,
  String parcelaId,
  String vendaId, {
  int valor = 5000,
  String forma = 'pix',
  DateTime? data,
  String? observacao,
}) => PagamentoDto(
  id: id,
  parcelaId: parcelaId,
  vendaId: vendaId,
  valor: valor,
  formaPagamento: forma,
  dataPagamento: data ?? DateTime.now(),
  observacao: observacao,
);

/// Service falso de recebimentos. Ao registrar, soma o valor na parcela do
/// [vendas] (como o banco faz pela view `resumo_parcelas`).
class ServicoRecebimentosFalso implements ServicoRecebimentos {
  ServicoRecebimentosFalso({
    required this.vendas,
    List<PagamentoDto>? pagamentos,
  }) : pagamentos = pagamentos ?? [];

  final ServicoVendasFalso vendas;
  List<PagamentoDto> pagamentos;
  bool falharRede = false;
  FalhaApp? falhaAoRegistrar;
  int _contador = 0;

  static const _falha = FalhaRede(
    'Sem conexão com a internet. Verifique e tente novamente.',
  );

  @override
  Future<Resultado<List<PagamentoDto>>> listarPagamentos(String vendaId) async {
    if (falharRede) return Erro(_falha);
    return Sucesso(
      pagamentos.where((p) => p.vendaId == vendaId).toList()
        ..sort((a, b) => b.dataPagamento.compareTo(a.dataPagamento)),
    );
  }

  @override
  Future<Resultado<String>> registrar({
    required String parcelaId,
    required int valorCentavos,
    required FormaPagamento forma,
    required DateTime data,
    String? observacao,
  }) async {
    if (falharRede) return Erro(_falha);
    if (falhaAoRegistrar case final falha?) return Erro(falha);
    final parcela = vendas.parcelas.firstWhere((p) => p.id == parcelaId);
    final id = 'pg-${++_contador}';
    pagamentos = [
      pagamentoDto(
        id,
        parcelaId,
        parcela.vendaId,
        valor: valorCentavos,
        forma: forma.valorBanco,
        data: data,
        observacao: observacao,
      ),
      ...pagamentos,
    ];
    vendas.parcelas = [
      for (final p in vendas.parcelas)
        if (p.id == parcelaId) _comPagamento(p, valorCentavos, data) else p,
    ];
    return Sucesso(id);
  }

  static ResumoParcelaDto _comPagamento(
    ResumoParcelaDto p,
    int valor,
    DateTime data,
  ) => ResumoParcelaDto(
    id: p.id,
    vendaId: p.vendaId,
    numeroParcela: p.numeroParcela,
    valor: p.valor,
    dataVencimento: p.dataVencimento,
    valorPago: p.valorPago + valor,
    qtdPagamentos: p.qtdPagamentos + 1,
    ultimoPagamento: data,
    vendaCodigo: p.vendaCodigo,
    dataVenda: p.dataVenda,
    vendaTotal: p.vendaTotal,
    qtdParcelas: p.qtdParcelas,
    clienteId: p.clienteId,
    clienteNome: p.clienteNome,
    clienteWhatsapp: p.clienteWhatsapp,
    nomesItens: p.nomesItens,
  );
}

/// Guarda o que foi compartilhado em vez de abrir o celular.
class ServicoCompartilharFalso implements ServicoCompartilhar {
  final List<({Uint8List png, String nomeArquivo, String texto})>
  compartilhados = [];
  bool falhar = false;

  @override
  Future<Resultado<void>> compartilharImagem({
    required Uint8List png,
    required String nomeArquivo,
    required String texto,
  }) async {
    if (falhar) {
      return Erro(const FalhaInesperada('Não foi possível compartilhar.'));
    }
    compartilhados.add((png: png, nomeArquivo: nomeArquivo, texto: texto));
    return const Sucesso(null);
  }
}

RepositorioRecebimentos repositorioRecebimentosDeTeste({
  required ServicoVendasFalso vendas,
  required ServicoRecebimentosFalso recebimentos,
  required RepositorioVendas repositorioVendas,
  required RepositorioClientes clientes,
  ServicoCompartilharFalso? compartilhar,
}) => RepositorioRecebimentos(
  vendas: vendas,
  recebimentos: recebimentos,
  repositorioVendas: repositorioVendas,
  clientes: clientes,
  compartilhar: compartilhar ?? ServicoCompartilharFalso(),
);
