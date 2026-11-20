// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/dto/boleto_dto.dart';
import 'package:sou_consultora/core/dto/resumo_venda_dto.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/repository/repositorio_boletos.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/ui/modules/financeiro/financeiro_cubit.dart';
import 'package:sou_consultora/ui/modules/financeiro/financeiro_screen.dart';

import '../../auxiliares/falsos_boletos.dart';
import '../../auxiliares/falsos_clientes.dart';
import '../../auxiliares/falsos_fornecedores.dart';
import '../../auxiliares/falsos_produtos.dart';
import '../../auxiliares/falsos_vendas.dart';
import '../../auxiliares/montar_app.dart';

class _Ambiente {
  _Ambiente({List<ResumoVendaDto>? vendas, List<BoletoDto>? boletos})
    : servicoVendas = ServicoVendasFalso(vendas: vendas),
      servicoBoletos = ServicoBoletosFalso(boletos: boletos) {
    this.vendas = repositorioVendasDeTeste(
      servicoVendas,
      produtos: repositorioProdutosDeTeste(ServicoProdutosFalso()),
      clientes: repositorioClientesDeTeste(ServicoClientesFalso()),
    );
    this.boletos = repositorioBoletosDeTeste(
      servicoBoletos,
      fornecedores: repositorioFornecedoresDeTeste(ServicoFornecedoresFalso()),
    );
  }

  final ServicoVendasFalso servicoVendas;
  final ServicoBoletosFalso servicoBoletos;
  late final RepositorioVendas vendas;
  late final RepositorioBoletos boletos;

  void registrar() {
    injetor
      ..registerSingleton<RepositorioVendas>(vendas)
      ..registerSingleton<RepositorioBoletos>(boletos);
  }
}

Future<void> _abrir(WidgetTester tester, _Ambiente ambiente) async {
  usarTelaDeCelular(tester);
  ambiente.registrar();
  Widget marcador(String texto) => Scaffold(body: Text(texto));
  final roteador = GoRouter(
    initialLocation: '/financeiro',
    routes: [
      GoRoute(
        path: '/financeiro',
        builder: (_, _) => const Scaffold(body: FinanceiroScreen()),
      ),
      GoRoute(path: '/a-receber', builder: (_, _) => marcador('a receber')),
      GoRoute(path: '/a-pagar', builder: (_, _) => marcador('a pagar')),
      GoRoute(path: '/vendas/nova', builder: (_, _) => marcador('nova venda')),
    ],
  );
  addTearDown(() async {
    roteador.dispose();
    await injetor.reset();
  });
  await tester.pumpWidget(appDeTeste(roteador: roteador));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('Financeiro (cubit)', () {
    final hoje = DateTime(2026, 11, 18, 9);

    _Ambiente comDados() => _Ambiente(
      vendas: [
        vendaDto('v1', total: 540000, data: DateTime(2026, 11, 3)),
        vendaDto('v2', total: 120000, data: DateTime(2026, 10, 15)),
      ],
      boletos: [
        boletoDto('b1', valor: 156000, vencimento: DateTime(2026, 11, 25)),
        boletoDto('b2', valor: 31000, vencimento: DateTime(2026, 10, 5)),
      ],
    );

    test('abre no mês atual e troca de período', () async {
      final ambiente = comDados();
      final cubit = FinanceiroCubit(
        vendas: ambiente.vendas,
        boletos: ambiente.boletos,
        agora: () => hoje,
      );
      addTearDown(cubit.close);
      await pumpEventQueue();

      expect(cubit.state.periodo, const MesAno(2026, 11));
      expect(cubit.state.resumo.faturamentoDoMes, 540000);
      expect(cubit.state.resumo.despesasDoMes, 156000);
      expect(cubit.state.resumo.totalAcumulado, 660000);

      cubit.alterarPeriodo(const MesAno(2026, 10));
      expect(cubit.state.resumo.faturamentoDoMes, 120000);
      expect(cubit.state.resumo.despesasDoMes, 31000);
      expect(cubit.state.resumo.meses.last.mes, const MesAno(2026, 10));
    });

    test('recalcula quando um boleto é lançado em A pagar', () async {
      final ambiente = comDados();
      final cubit = FinanceiroCubit(
        vendas: ambiente.vendas,
        boletos: ambiente.boletos,
        agora: () => hoje,
      );
      addTearDown(cubit.close);
      await pumpEventQueue();

      ambiente.servicoBoletos.boletos = [
        ...ambiente.servicoBoletos.boletos,
        boletoDto('b3', valor: 4000, vencimento: DateTime(2026, 11, 30)),
      ];
      await ambiente.boletos.carregar();
      await pumpEventQueue();
      expect(cubit.state.resumo.despesasDoMes, 160000);
    });

    test('erro de rede mostra a mensagem', () async {
      final ambiente = comDados()..servicoBoletos.falharRede = true;
      final cubit = FinanceiroCubit(
        vendas: ambiente.vendas,
        boletos: ambiente.boletos,
        agora: () => hoje,
      );
      addTearDown(cubit.close);
      await pumpEventQueue();
      expect(cubit.state.mensagemErro, contains('Sem conexão'));
    });
  });

  group('Financeiro (tela)', () {
    testWidgets('período atual, total, gráfico e categorias', (tester) async {
      final hoje = DateTime.now();
      await _abrir(
        tester,
        _Ambiente(
          vendas: [vendaDto('v1', total: 540000, data: hoje)],
          boletos: [boletoDto('b1', valor: 156000, vencimento: hoje)],
        ),
      );

      expect(find.text('Financeiro'), findsOneWidget);
      expect(find.textContaining('(Mês atual)'), findsOneWidget);
      expect(find.text('Faturamento - Últimos 12 meses'), findsOneWidget);
      expect(find.text('R\$ 5.400'), findsOneWidget);
      expect(find.text('5.4k'), findsOneWidget);
      expect(
        find.textContaining(
          'Faturamento: R\$ 5.400,00',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Despesas: R\$ 1.560,00',
          findRichText: true,
        ),
        findsOneWidget,
      );
      // 12 barras com descrição para o leitor de tela.
      expect(
        find.bySemanticsLabel(RegExp(r'^\p{L}+ / \d{4}: R\$', unicode: true)),
        findsNWidgets(12),
      );
    });

    for (final (alvo, destino) in [
      (find.text('A Receber'), 'a receber'),
      (find.text('A Pagar'), 'a pagar'),
      (find.byTooltip('Nova venda'), 'nova venda'),
    ]) {
      testWidgets('abre $destino', (tester) async {
        await _abrir(tester, _Ambiente());
        await tester.tap(alvo);
        await tester.pumpAndSettle();
        expect(find.text(destino), findsOneWidget);
      });
    }

    testWidgets('sem vendas nem boletos: tudo zero', (tester) async {
      await _abrir(tester, _Ambiente());
      expect(find.text('R\$ 0'), findsOneWidget);
      expect(
        find.textContaining('Faturamento: R\$ 0,00', findRichText: true),
        findsOneWidget,
      );
    });
  });
}
