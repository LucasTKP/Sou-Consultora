import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sou_consultora/core/dto/item_venda_dto.dart';
import 'package:sou_consultora/core/dto/resumo_parcela_dto.dart';
import 'package:sou_consultora/core/dto/resumo_venda_dto.dart';
import 'package:sou_consultora/core/model/chave_pix.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/forma_pagamento.dart';
import 'package:sou_consultora/core/model/item_venda.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/core/model/pedido_venda.dart';
import 'package:sou_consultora/core/model/plano_parcelas.dart';
import 'package:sou_consultora/core/model/venda.dart';
import 'package:sou_consultora/ui/formatadores/mensagem_cobranca.dart';

ResumoVenda _venda({
  int codigo = 12,
  String cliente = 'Carla Mendes',
  int total = 24000,
  int saldo = 0,
  int atrasado = 0,
  DateTime? data,
  String itens = 'Kit Lily | Batom',
}) => ResumoVenda(
  id: 'v$codigo',
  codigo: codigo,
  clienteId: 'c1',
  clienteNome: cliente,
  clienteWhatsapp: '11987654321',
  dataVenda: data ?? DateTime(2026, 11, 10, 14, 30),
  subtotal: total,
  totalDescontos: 0,
  total: total,
  qtdItens: 2,
  nomesItens: itens,
  primeiroItem: 'Kit Lily',
  saldo: saldo,
  valorAtrasado: atrasado,
);

ResumoParcela _parcela({
  int valor = 12000,
  int pago = 0,
  DateTime? vencimento,
}) => ResumoParcela(
  id: 'p1',
  vendaId: 'v1',
  numero: 2,
  valor: valor,
  valorPago: pago,
  vencimento: vencimento ?? DateTime(2026, 11, 15),
  vendaCodigo: 12,
  dataVenda: DateTime(2026, 10, 15),
  vendaTotal: 24000,
  qtdParcelas: 2,
  clienteId: 'c1',
  clienteNome: 'Carla Menezes',
  clienteWhatsapp: '11987654321',
);

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  final hoje = DateTime(2026, 11, 17, 10);

  group('Venda', () {
    test('status, código, títulos e busca', () {
      expect(_venda().status, StatusVenda.quitada);
      expect(_venda(saldo: 100).status, StatusVenda.emAberto);
      expect(_venda(saldo: 100, atrasado: 100).status, StatusVenda.atrasada);
      expect(_venda().codigoTexto, '#0012');
      expect(_venda().tituloItens, 'Kit Lily + 1 item');
      expect(_venda().combinaBusca('12'), isTrue);
      expect(_venda().combinaBusca('#0012'), isTrue);
      expect(_venda().combinaBusca('1'), isFalse);
      expect(_venda().combinaBusca('carla'), isTrue);
      expect(_venda().combinaBusca('batom'), isTrue);
    });
  });

  group('Parcela', () {
    test('status pago, atrasada, parcial e a receber', () {
      expect(_parcela(pago: 12000).status(hoje: hoje), StatusParcela.pago);
      expect(_parcela().status(hoje: hoje), StatusParcela.atrasada);
      expect(
        _parcela(vencimento: DateTime(2026, 11, 17)).status(hoje: hoje),
        StatusParcela.aReceber,
      );
      expect(
        _parcela(
          pago: 5000,
          vencimento: DateTime(2026, 12, 1),
        ).status(hoje: hoje),
        StatusParcela.parcial,
      );
      expect(_parcela(pago: 5000).saldo, 7000);
      expect(_parcela().diasAtraso(hoje: hoje), 2);
      expect(_parcela().textoNumero, '2 de 2');
    });
  });

  group('Itens do pedido', () {
    test('subtotal, desconto, estoque e formato para gravar', () {
      const item = ItemPedido(
        tipo: TipoItem.produto,
        catalogoId: 'p1',
        nome: 'Kit Lily',
        precoUnitario: 19600,
        quantidade: 1,
        desconto: 1600,
        saldoEstoque: 2,
      );
      expect(item.subtotal, 18000);
      expect(item.paraGravar(), {
        'produto_id': 'p1',
        'quantidade': 1,
        'desconto': 16.0,
        'baixar_estoque': true,
      });
      expect(
        ItemPedido.validarQuantidade(quantidade: 3, baixa: true, saldo: 2),
        'Estoque insuficiente: 2 un disponíveis',
      );
      expect(
        ItemPedido.validarQuantidade(quantidade: 3, baixa: false, saldo: 2),
        isNull,
      );
      expect(
        ItemPedido.validarDesconto(desconto: 20001, bruto: 20000),
        isNotNull,
      );
      const servico = ItemPedido(
        tipo: TipoItem.servico,
        catalogoId: 's1',
        nome: 'Sobrancelha',
        precoUnitario: 4500,
        quantidade: 1,
      );
      expect(servico.paraGravar()['baixar_estoque'], isFalse);
      expect(servico.paraGravar().containsKey('produto_id'), isFalse);
      expect(PedidoVenda.totalDe([item, servico]), 22500);
      expect(PedidoVenda.descontosDe([item, servico]), 1600);
    });

    test('pedido para gravar e data futura', () {
      final pedido = PedidoVenda(
        clienteId: 'c1',
        dataVenda: DateTime(2026, 11, 17),
        itens: const [],
        parcelas: [
          ParcelaPlano(valor: 6000, vencimento: DateTime(2026, 12, 5)),
        ],
        entrada: FormaPagamento.pix,
      );
      final dados = pedido.paraGravar();
      expect(dados['p_data_venda'], '2026-11-17');
      expect(dados['p_pagamento'], {'forma': 'pix'});
      expect((dados['p_parcelas'] as List).single, {
        'valor': 60.0,
        'data_vencimento': '2026-12-05',
      });
      expect(dados.containsKey('p_consultora_id'), isFalse);
      expect(
        PedidoVenda.validarDataVenda(DateTime(2026, 11, 18), hoje: hoje),
        isNotNull,
      );
    });
  });

  group('Plano de parcelas', () {
    test('sugestão com centavos na última e meses seguidos', () {
      final plano = PlanoParcelas.sugerir(
        total: 10000,
        quantidade: 3,
        primeiroVencimento: DateTime(2026, 12, 10),
      );
      expect(plano.map((p) => p.valor), [3333, 3333, 3334]);
      expect(plano.map((p) => p.vencimento), [
        DateTime(2026, 12, 10),
        DateTime(2027, 1, 10),
        DateTime(2027, 2, 10),
      ]);
      expect(PlanoParcelas.fecha(10000, plano), isTrue);
      final alterado = [plano[0].copyWith(valor: 3000), plano[1], plano[2]];
      expect(PlanoParcelas.diferenca(10000, alterado), 333);
      expect(PlanoParcelas.fecha(10000, alterado), isFalse);
    });

    test('fim de mês fica no último dia', () {
      expect(
        PlanoParcelas.somarMeses(DateTime(2027, 1, 31), 1),
        DateTime(2027, 2, 28),
      );
      expect(
        PlanoParcelas.somarMeses(DateTime(2026, 11, 30), 3),
        DateTime(2027, 2, 28),
      );
    });
  });

  group('Filtro de vendas', () {
    test('mês, status, busca, ordem e contagens', () {
      final vendas = [
        _venda(codigo: 1, data: DateTime(2026, 11, 2)),
        _venda(codigo: 2, saldo: 100, data: DateTime(2026, 11, 9)),
        _venda(
          codigo: 3,
          saldo: 100,
          atrasado: 100,
          data: DateTime(2026, 10, 9),
        ),
      ];
      List<int> codigos({
        StatusFiltroVenda status = StatusFiltroVenda.todas,
        MesAno? mes = const MesAno(2026, 11),
        OrdemData ordem = OrdemData.recentes,
      }) => FiltroVendas.aplicar(
        vendas,
        status: status,
        mes: mes,
        busca: '',
        ordem: ordem,
      ).map((v) => v.codigo).toList();

      expect(codigos(), [2, 1]);
      expect(codigos(ordem: OrdemData.antigas), [1, 2]);
      expect(codigos(mes: null), [2, 1, 3]);
      expect(codigos(status: StatusFiltroVenda.atrasada, mes: null), [3]);
      expect(
        FiltroVendas.contagens(
          vendas,
          const MesAno(2026, 11),
        )[StatusFiltroVenda.emAberto],
        1,
      );
      expect(FiltroVendas.meses(vendas, hoje: hoje), [
        const MesAno(2026, 11),
        const MesAno(2026, 10),
      ]);
    });
  });

  group('Mensagem de cobrança', () {
    test('com chave Pix', () {
      final texto = MensagemCobranca.montar(
        parcela: _parcela(),
        nomeConsultora: 'Ana Paula',
        chavePix: ChavePix(tipo: TipoChavePix.email, valor: 'ana@email.com'),
      );
      expect(texto, contains('Oi, Carla!'));
      expect(texto, contains('parcela 2 de 2 da sua compra #0012'));
      expect(texto, contains('R\$ 120,00'));
      expect(texto, contains('15/11/2026'));
      expect(texto, contains('pagar pelo Pix'));
      expect(texto, contains('ana@email.com'));
      expect(texto, endsWith('Ana Paula'));
    });

    test('sem chave Pix não fala de Pix', () {
      final texto = MensagemCobranca.montar(
        parcela: _parcela(),
        nomeConsultora: 'Ana',
      );
      expect(texto, isNot(contains('Pix')));
    });
  });

  group('DTOs', () {
    test('venda, item e parcela', () {
      final venda = ResumoVendaDto.fromJson({
        'id': 'v1',
        'codigo': 12,
        'cliente_id': 'c1',
        'cliente_nome': 'Carla',
        'cliente_whatsapp': '11987654321',
        'data_venda': '2026-11-10T17:30:00Z',
        'subtotal': '241.00',
        'total_descontos': 21,
        'total': 220,
        'observacoes': null,
        'qtd_itens': 2,
        'qtd_unidades': 2,
        'nomes_itens': 'A | B',
        'primeiro_item': 'A',
        'qtd_parcelas': 2,
        'qtd_parcelas_pagas': 1,
        'valor_pago': 120,
        'saldo': 100,
        'valor_atrasado': 0,
        'proximo_vencimento': '2026-12-10',
        'tem_pagamento': true,
      }).paraModel();
      expect(venda.subtotal, 24100);
      expect(venda.podeEditar, isFalse);
      expect(venda.proximoVencimento, DateTime(2026, 12, 10));

      final item = ItemVendaDto.fromJson({
        'id': 'i1',
        'venda_id': 'v1',
        'produto_id': null,
        'servico_id': 's1',
        'nome': 'Sobrancelha',
        'foto_url': null,
        'categoria_servico': 'Sobrancelha',
        'quantidade': 1,
        'preco_unitario': 45,
        'custo_unitario': 0,
        'desconto': 5,
        'subtotal': 40,
        'baixar_estoque': false,
      }).paraModel();
      expect(item.tipo, TipoItem.servico);
      expect(item.catalogoId, 's1');
      expect(item.subtotal, 4000);

      final parcela = ResumoParcelaDto.fromJson({
        'id': 'p1',
        'venda_id': 'v1',
        'numero_parcela': 1,
        'valor': 120,
        'data_vencimento': '2026-10-15',
        'valor_pago': 50,
        'qtd_pagamentos': 1,
        'ultimo_pagamento': '2026-10-15T15:00:00Z',
        'venda_codigo': 12,
        'data_venda': '2026-10-15T15:00:00Z',
        'venda_total': 240,
        'qtd_parcelas': 2,
        'cliente_id': 'c1',
        'cliente_nome': 'Carla',
        'cliente_whatsapp': '11987654321',
      }).paraModel();
      expect(parcela.saldo, 7000);
      expect(parcela.vencimento, DateTime(2026, 10, 15));
    });
  });
}
