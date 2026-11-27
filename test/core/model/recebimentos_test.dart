import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/dto/pagamento_dto.dart';
import 'package:sou_consultora/core/model/detalhe_parcela.dart';
import 'package:sou_consultora/core/model/filtro_recebimentos.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/forma_pagamento.dart';
import 'package:sou_consultora/core/model/pagamento.dart';
import 'package:sou_consultora/core/model/parcela.dart';

import '../../auxiliares/falsos_vendas.dart';

ResumoParcela _parcela(
  String id, {
  required DateTime vencimento,
  int valor = 10000,
  int pago = 0,
  String cliente = 'Carla',
  String itens = 'Kit Lily',
  int numero = 1,
  int qtd = 1,
}) => ResumoParcela(
  id: id,
  vendaId: 'v-$id',
  numero: numero,
  valor: valor,
  valorPago: pago,
  vencimento: vencimento,
  vendaCodigo: 1,
  dataVenda: DateTime(2026, 10, 1),
  vendaTotal: valor,
  qtdParcelas: qtd,
  clienteId: 'c1',
  clienteNome: cliente,
  clienteWhatsapp: '11987654321',
  nomesItens: itens,
);

void main() {
  final hoje = DateTime(2026, 11, 17, 9);
  final parcelas = [
    _parcela('atrasada', vencimento: DateTime(2026, 11, 15), valor: 12000),
    _parcela(
      'hoje',
      vencimento: DateTime(2026, 11, 17),
      valor: 7000,
      cliente: 'Beatriz',
    ),
    _parcela(
      'futura',
      vencimento: DateTime(2026, 11, 25),
      valor: 15000,
      itens: 'Batom',
    ),
    _parcela(
      'paga',
      vencimento: DateTime(2026, 11, 10),
      valor: 6500,
      pago: 6500,
    ),
    _parcela('outubro', vencimento: DateTime(2026, 10, 10)),
  ];

  List<String> ids({
    StatusFiltroRecebimento status = StatusFiltroRecebimento.todos,
    MesAno? mes = const MesAno(2026, 11),
    String busca = '',
    OrdemRecebimento ordem = OrdemRecebimento.vencimentoProximo,
  }) => FiltroRecebimentos.aplicar(
    parcelas,
    status: status,
    mes: mes,
    busca: busca,
    ordem: ordem,
    hoje: hoje,
  ).map((p) => p.id).toList();

  test('status: a receber, atrasado, vence hoje e pago', () {
    expect(ids(status: StatusFiltroRecebimento.atrasado), ['atrasada']);
    expect(ids(status: StatusFiltroRecebimento.venceHoje), ['hoje']);
    expect(ids(status: StatusFiltroRecebimento.aReceber), ['futura']);
    expect(ids(status: StatusFiltroRecebimento.pago), ['paga']);
    expect(
      FiltroRecebimentos.contagens(
        parcelas,
        const MesAno(2026, 11),
        hoje: hoje,
      )[StatusFiltroRecebimento.todos],
      4,
    );
  });

  test('mês pelo vencimento, busca por produto e ordens', () {
    expect(ids(mes: null).length, 5);
    expect(ids(busca: 'batom'), ['futura']);
    expect(ids(busca: 'beatriz'), ['hoje']);
    expect(ids(), ['paga', 'atrasada', 'hoje', 'futura']);
    expect(ids(ordem: OrdemRecebimento.maiorValor).first, 'futura');
    expect(ids(ordem: OrdemRecebimento.menorValor).first, 'paga');
  });

  test('textos da parcela', () {
    expect(parcelas.first.textoCurto, 'Parcela única');
    expect(
      _parcela('x', vencimento: hoje, numero: 2, qtd: 2).textoCurto,
      'Parcela 2/2',
    );
    expect(parcelas.first.codigoVenda, '#0001');
  });

  test('validação do pagamento', () {
    expect(
      Pagamento.validarValor(null, saldo: 7000),
      'Informe o valor recebido',
    );
    expect(Pagamento.validarValor(8000, saldo: 7000), isNotNull);
    expect(Pagamento.validarValor(7000, saldo: 7000), isNull);
    expect(
      Pagamento.validarData(DateTime(2026, 11, 18), hoje: hoje),
      isNotNull,
    );
  });

  test('DTO do pagamento', () {
    final pagamento = PagamentoDto.fromJson({
      'id': 'pg1',
      'parcela_id': 'p1',
      'venda_id': 'v1',
      'valor': '50.00',
      'forma_pagamento': 'dinheiro',
      'data_pagamento': '2026-10-15T15:00:00Z',
      'observacao': null,
    }).paraModel();
    expect(pagamento.valor, 5000);
    expect(pagamento.forma, FormaPagamento.dinheiro);
  });

  test('comprovante: pagamento pelo id e saldo da venda', () {
    Pagamento pagamento(String id, DateTime data) => Pagamento(
      id: id,
      parcelaId: 'p2',
      vendaId: 'v1',
      valor: 2000,
      forma: FormaPagamento.pix,
      data: data,
    );
    final detalhe = DetalheParcela(
      parcela: _parcela('p2', vencimento: DateTime(2026, 11, 15), pago: 4000),
      // Do mais recente ao mais antigo: o retroativo (10/11) vem por último.
      pagamentos: [
        pagamento('hoje', DateTime(2026, 11, 17)),
        pagamento('retroativo', DateTime(2026, 11, 10)),
      ],
      parcelasDaVenda: [
        _parcela('p1', vencimento: DateTime(2026, 10, 15), pago: 10000),
        _parcela('p2', vencimento: DateTime(2026, 11, 15), pago: 4000),
      ],
      venda: vendaDto('v1').paraModel(),
    );

    expect(detalhe.pagamentoDoComprovante(null)?.id, 'hoje');
    expect(detalhe.pagamentoDoComprovante('retroativo')?.id, 'retroativo');
    expect(detalhe.pagamentoDoComprovante('outro')?.id, 'hoje');
    expect(detalhe.saldoDaVenda, 6000);
  });
}
