import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/dto/lembrete_recompra_dto.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/lembrete_recompra.dart';
import 'package:sou_consultora/core/model/resumo_inicio.dart';
import 'package:sou_consultora/ui/formatadores/mensagem_recompra.dart';

import '../../auxiliares/falsos_boletos.dart';
import '../../auxiliares/falsos_clientes.dart';
import '../../auxiliares/falsos_inicio.dart';
import '../../auxiliares/falsos_recebimentos.dart';
import '../../auxiliares/falsos_vendas.dart';

void main() {
  final hoje = DateTime(2026, 11, 18, 14);

  LembreteRecompra lembrete({
    required int diasAtras,
    int duracao = 60,
    String cliente = 'Carla Menezes',
    String produto = 'Lily',
  }) => lembreteDto(
    cliente: cliente,
    produto: produto,
    durabilidade: duracao,
    ultimaCompra: DateTime(2026, 11, 18 - diasAtras),
  ).paraModel();

  group('Lembrete de recompra', () {
    test('janela: 7 dias antes, acabando até 60 depois', () {
      // Duração 60: a previsão é 60 dias depois da compra.
      expect(lembrete(diasAtras: 52).situacao(hoje: hoje), isNull);
      expect(
        lembrete(diasAtras: 53).situacao(hoje: hoje),
        SituacaoLembrete.cicloIdeal,
      );
      expect(
        lembrete(diasAtras: 60).situacao(hoje: hoje),
        SituacaoLembrete.cicloIdeal,
      );
      expect(
        lembrete(diasAtras: 62).situacao(hoje: hoje),
        SituacaoLembrete.acabando,
      );
      expect(
        lembrete(diasAtras: 120).situacao(hoje: hoje),
        SituacaoLembrete.acabando,
      );
      expect(lembrete(diasAtras: 121).situacao(hoje: hoje), isNull);
    });

    test('previsão e dias pelo calendário (atravessando meses)', () {
      final l = lembrete(diasAtras: 62);
      expect(l.previsao, DateTime(2026, 11, 16));
      expect(l.diasDesdePrevisao(hoje: hoje), 2);
      expect(l.diasDesdeCompra(hoje: hoje), 62);
    });

    test('DTO da view', () {
      final l = LembreteRecompraDto.fromJson({
        'cliente_id': 'c1',
        'cliente_nome': 'Carla',
        'cliente_whatsapp': '11987654321',
        'produto_id': 'p1',
        'produto_nome': 'Lily',
        'durabilidade_dias': 90,
        'ultima_compra': '2026-09-01',
      }).paraModel();
      expect(l.durabilidadeDias, 90);
      expect(l.ultimaCompra, DateTime(2026, 9, 1));
    });

    test('mensagem do WhatsApp sem artigo de gênero', () {
      final texto = MensagemRecompra.montar(
        lembrete: lembrete(diasAtras: 62, produto: 'Base Líquida Matte'),
        diasDesdeCompra: 62,
        nomeConsultora: 'Ana Paula Silva',
      );
      expect(
        texto,
        'Oi, Carla! Tudo bem? 😊\n'
        'Já faz 62 dias da sua compra de Base Líquida Matte. '
        'Deve estar acabando por aí! Quer que eu separe mais um para você?\n'
        '\n'
        'Beijos! 💖 Ana',
      );
    });
  });

  group('ResumoInicio', () {
    ResumoInicio calcular({
      List<LembreteRecompra>? lembretes,
    }) => ResumoInicio.calcular(
      vendas: [
        vendaDto('v1', total: 240000, data: DateTime(2026, 11, 3)),
        vendaDto('v2', total: 144000, data: DateTime(2026, 11, 17)),
        vendaDto('v3', total: 99900, data: DateTime(2026, 10, 30)),
      ].map((v) => v.paraModel()).toList(),
      pagamentos: [
        // Parcela de outubro paga em novembro conta no Recebido de novembro.
        pagamentoDto(
          'pg1',
          'pa-out',
          'v3',
          valor: 5000,
          data: DateTime(2026, 11, 2),
        ),
        pagamentoDto(
          'pg2',
          'pa-nov',
          'v1',
          valor: 12000,
          data: DateTime(2026, 11, 10),
        ),
        pagamentoDto(
          'pg3',
          'pa-out',
          'v3',
          valor: 3000,
          data: DateTime(2026, 10, 31),
        ),
      ].map((p) => p.paraModel()).toList(),
      parcelas: [
        parcelaDto(
          'a1',
          'v1',
          clienteId: 'c1',
          valor: 10000,
          vencimento: DateTime(2026, 11, 1),
        ),
        parcelaDto(
          'a2',
          'v2',
          clienteId: 'c1',
          valor: 8000,
          pago: 3000,
          vencimento: DateTime(2026, 10, 20),
        ),
        parcelaDto(
          'a3',
          'v3',
          clienteId: 'c2',
          valor: 10000,
          vencimento: DateTime(2026, 11, 15),
        ),
        parcelaDto(
          'paga',
          'v3',
          clienteId: 'c3',
          valor: 5000,
          pago: 5000,
          vencimento: DateTime(2026, 11, 1),
        ),
        parcelaDto(
          'futura',
          'v3',
          clienteId: 'c4',
          valor: 5000,
          vencimento: DateTime(2026, 12, 1),
        ),
      ].map((p) => p.paraModel()).toList(),
      boletos: [
        boletoDto('venceu3', vencimento: DateTime(2026, 11, 15), valor: 1000),
        boletoDto('hoje', vencimento: DateTime(2026, 11, 18), valor: 2000),
        boletoDto('amanha', vencimento: DateTime(2026, 11, 19), valor: 84250),
        boletoDto('venceu10', vencimento: DateTime(2026, 11, 8), valor: 4000),
        boletoDto('depois', vencimento: DateTime(2026, 11, 20), valor: 5000),
        boletoDto(
          'pago',
          vencimento: DateTime(2026, 11, 17),
          valor: 6000,
          pagoEm: DateTime(2026, 11, 17),
        ),
        boletoDto('dezembro', vencimento: DateTime(2026, 12, 1), valor: 7000),
      ].map((b) => b.paraModel()).toList(),
      lembretes: lembretes ?? const [],
      hoje: hoje,
    );

    test('números do mês', () {
      final r = calcular();
      expect(r.vendidoNoMes, 384000);
      expect(r.qtdVendasNoMes, 2);
      expect(r.recebidoNoMes, 17000);
      // Pagos ou não, pelo vencimento no mês (dezembro fora).
      expect(r.boletosNoMes, 1000 + 2000 + 84250 + 4000 + 5000 + 6000);
    });

    test(
      'alertas de boleto: não pagos até amanhã, do mais atrasado, até 3',
      () {
        final r = calcular();
        expect(r.alertasBoletos.map((a) => a.boleto.id), [
          'venceu10',
          'venceu3',
          'hoje',
        ]);
        expect(r.alertasBoletos.map((a) => a.diasParaVencer), [-10, -3, 0]);
        final todos = ResumoInicio.alertasDeBoletos(
          [
            boletoDto('amanha', vencimento: DateTime(2026, 11, 19)),
            boletoDto('depois', vencimento: DateTime(2026, 11, 20)),
          ].map((b) => b.paraModel()).toList(),
          hoje: hoje,
        );
        expect(todos.single.diasParaVencer, 1);
      },
    );

    test('vendas atrasadas: clientes distintas e soma dos saldos', () {
      final atrasadas = calcular().atrasadas!;
      expect(atrasadas.qtdClientes, 2);
      expect(atrasadas.qtdParcelas, 3);
      expect(atrasadas.total, 10000 + 5000 + 10000);
      expect(calcular().qtdAlertas, 4);
    });

    test('lembretes: só na janela, do mais urgente, até 3', () {
      final r = calcular(
        lembretes: [
          lembrete(diasAtras: 30, cliente: 'Cedo'),
          lembrete(diasAtras: 55, cliente: 'Ciclo'),
          lembrete(diasAtras: 90, cliente: 'Muito'),
          lembrete(diasAtras: 62, cliente: 'Pouco'),
          lembrete(diasAtras: 70, cliente: 'Medio'),
          lembrete(diasAtras: 200, cliente: 'Passou'),
        ],
      );
      expect(r.lembretes.map((l) => l.lembrete.clienteNome), [
        'Muito',
        'Medio',
        'Pouco',
      ]);
      expect(r.lembretes.first.diasDesdeCompra, 90);
      expect(
        ResumoInicio.lembretesAtivos([
          lembrete(diasAtras: 55, cliente: 'Ciclo'),
        ], hoje: hoje).single.situacao,
        SituacaoLembrete.cicloIdeal,
      );
    });

    test('sem nada: tudo zero, sem alertas', () {
      final r = ResumoInicio.calcular(
        vendas: const [],
        pagamentos: const [],
        parcelas: const [],
        boletos: const [],
        lembretes: const [],
        hoje: hoje,
      );
      expect(r.vendidoNoMes, 0);
      expect(r.atrasadas, isNull);
      expect(r.qtdAlertas, 0);
      expect(r.lembretes, isEmpty);
    });
  });

  group('Repositório do Início', () {
    test('lembretes, todos os pagamentos e WhatsApp', () async {
      final whatsapp = ServicoWhatsappFalso();
      final recebimentos = ServicoRecebimentosFalso(
        vendas: ServicoVendasFalso(),
        pagamentos: [pagamentoDto('pg1', 'pa1', 'v1', valor: 5000)],
      );
      final repositorio = repositorioInicioDeTeste(
        servico: ServicoInicioFalso(
          lembretes: [lembreteDto(ultimaCompra: DateTime(2026, 9, 1))],
        ),
        recebimentos: recebimentos,
        whatsapp: whatsapp,
      );

      final lembretes = await repositorio.lembretes();
      expect((lembretes as Sucesso).valor, hasLength(1));
      final pagamentos = await repositorio.pagamentos();
      expect((pagamentos as Sucesso).valor.single.valor, 5000);
      await repositorio.abrirWhatsapp('11987654321', 'Oi!');
      expect(whatsapp.mensagens, ['Oi!']);
    });
  });
}
