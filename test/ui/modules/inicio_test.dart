// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/dto/boleto_dto.dart';
import 'package:sou_consultora/core/dto/lembrete_recompra_dto.dart';
import 'package:sou_consultora/core/dto/pagamento_dto.dart';
import 'package:sou_consultora/core/dto/resumo_parcela_dto.dart';
import 'package:sou_consultora/core/dto/resumo_venda_dto.dart';
import 'package:sou_consultora/core/repository/repositorio_boletos.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_inicio.dart';
import 'package:sou_consultora/core/repository/repositorio_recebimentos.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/ui/modules/inicio/inicio_cubit.dart';
import 'package:sou_consultora/ui/modules/inicio/inicio_screen.dart';

import '../../auxiliares/falsos_boletos.dart';
import '../../auxiliares/falsos_clientes.dart';
import '../../auxiliares/falsos_consultora.dart';
import '../../auxiliares/falsos_fornecedores.dart';
import '../../auxiliares/falsos_inicio.dart';
import '../../auxiliares/falsos_produtos.dart';
import '../../auxiliares/falsos_recebimentos.dart';
import '../../auxiliares/falsos_vendas.dart';
import '../../auxiliares/montar_app.dart';

class _Ambiente {
  _Ambiente({
    List<ResumoVendaDto>? vendas,
    List<ResumoParcelaDto>? parcelas,
    List<PagamentoDto>? pagamentos,
    List<BoletoDto>? boletos,
    List<LembreteRecompraDto>? lembretes,
  }) : servicoVendas = ServicoVendasFalso(vendas: vendas, parcelas: parcelas),
       servicoBoletos = ServicoBoletosFalso(boletos: boletos),
       servicoInicio = ServicoInicioFalso(lembretes: lembretes),
       whatsapp = ServicoWhatsappFalso() {
    servicoRecebimentos = ServicoRecebimentosFalso(
      vendas: servicoVendas,
      pagamentos: pagamentos,
    );
    final clientes = repositorioClientesDeTeste(ServicoClientesFalso());
    this.vendas = repositorioVendasDeTeste(
      servicoVendas,
      produtos: repositorioProdutosDeTeste(ServicoProdutosFalso()),
      clientes: clientes,
    );
    recebimentos = repositorioRecebimentosDeTeste(
      vendas: servicoVendas,
      recebimentos: servicoRecebimentos,
      repositorioVendas: this.vendas,
      clientes: clientes,
    );
    this.boletos = repositorioBoletosDeTeste(
      servicoBoletos,
      fornecedores: repositorioFornecedoresDeTeste(ServicoFornecedoresFalso()),
    );
    inicio = repositorioInicioDeTeste(
      servico: servicoInicio,
      recebimentos: servicoRecebimentos,
      whatsapp: whatsapp,
    );
    consultora = repositorioDeTeste(
      ServicoConsultoraFalso(registro: dtoDeTeste(nome: 'Ana Paula Silva')),
    );
  }

  final ServicoVendasFalso servicoVendas;
  final ServicoBoletosFalso servicoBoletos;
  final ServicoInicioFalso servicoInicio;
  final ServicoWhatsappFalso whatsapp;
  late final ServicoRecebimentosFalso servicoRecebimentos;
  late final RepositorioVendas vendas;
  late final RepositorioRecebimentos recebimentos;
  late final RepositorioBoletos boletos;
  late final RepositorioInicio inicio;
  late final RepositorioConsultora consultora;

  InicioCubit cubit(DateTime hoje) => InicioCubit(
    vendas: vendas,
    recebimentos: recebimentos,
    boletos: boletos,
    inicio: inicio,
    consultora: consultora,
    agora: () => hoje,
  );

  void registrar() {
    injetor
      ..registerSingleton<RepositorioVendas>(vendas)
      ..registerSingleton<RepositorioRecebimentos>(recebimentos)
      ..registerSingleton<RepositorioBoletos>(boletos)
      ..registerSingleton<RepositorioInicio>(inicio)
      ..registerSingleton<RepositorioConsultora>(consultora);
  }
}

Future<void> _abrir(WidgetTester tester, _Ambiente ambiente) async {
  usarTelaDeCelular(tester);
  ambiente.registrar();
  await injetor<RepositorioConsultora>().buscarMinha();
  Widget marcador(String texto) => Scaffold(body: Text(texto));
  final roteador = GoRouter(
    initialLocation: '/inicio',
    routes: [
      GoRoute(
        path: '/inicio',
        builder: (_, _) => const Scaffold(body: InicioScreen()),
      ),
      GoRoute(path: '/vendas', builder: (_, _) => marcador('vendas')),
      GoRoute(path: '/clientes', builder: (_, _) => marcador('clientes')),
      GoRoute(path: '/a-pagar', builder: (_, _) => marcador('a pagar')),
      GoRoute(
        path: '/a-pagar/:id',
        builder: (_, e) => marcador('boleto ${e.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/a-receber',
        builder: (_, e) =>
            marcador('a receber ${e.uri.queryParameters['status']}'),
      ),
    ],
  );
  addTearDown(() async {
    roteador.dispose();
    await injetor.reset();
  });
  await tester.pumpWidget(appDeTeste(roteador: roteador));
  await tester.pumpAndSettle();
}

/// Dia de hoje menos [dias] (pelo calendário).
DateTime _diasAtras(int dias) {
  final hoje = DateTime.now();
  return DateTime(hoje.year, hoje.month, hoje.day - dias);
}

_Ambiente _comTudo() => _Ambiente(
  vendas: [vendaDto('v1', total: 384000, data: DateTime.now())],
  pagamentos: [
    pagamentoDto('pg1', 'pa1', 'v1', valor: 245000, data: DateTime.now()),
  ],
  parcelas: [
    parcelaDto(
      'pa1',
      'v1',
      clienteId: 'c1',
      valor: 10000,
      vencimento: _diasAtras(5),
    ),
    parcelaDto(
      'pa2',
      'v1',
      clienteId: 'c2',
      valor: 18000,
      vencimento: _diasAtras(2),
    ),
  ],
  boletos: [
    boletoDto(
      'b1',
      fornecedor: 'Natura',
      valor: 84250,
      vencimento: _diasAtras(-1),
    ),
  ],
  lembretes: [
    lembreteDto(
      cliente: 'Dona Carla',
      produto: 'Lily Eau de Parfum 75ml',
      ultimaCompra: _diasAtras(62),
    ),
  ],
);

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('Início (cubit)', () {
    test('cumprimento pela hora com o primeiro nome', () async {
      String cumprimento(int hora) {
        final cubit = _Ambiente().cubit(DateTime(2026, 11, 18, hora));
        addTearDown(cubit.close);
        return cubit.state.cumprimento;
      }

      expect(cumprimento(8), 'Bom dia!');
      final ambiente = _Ambiente();
      await ambiente.consultora.buscarMinha();
      final cubit = ambiente.cubit(DateTime(2026, 11, 18, 14));
      addTearDown(cubit.close);
      expect(cubit.state.cumprimento, 'Boa tarde, Ana!');
      expect(cumprimento(11), startsWith('Bom dia'));
      expect(cumprimento(12), startsWith('Boa tarde'));
      expect(cumprimento(18), startsWith('Boa noite'));
    });

    test('recalcula quando um boleto é pago em A pagar', () async {
      final ambiente = _comTudo();
      final cubit = ambiente.cubit(DateTime.now());
      addTearDown(cubit.close);
      await pumpEventQueue();
      expect(cubit.state.resumo.alertasBoletos, hasLength(1));

      await ambiente.boletos.pagar('b1', DateTime.now());
      await pumpEventQueue();
      expect(cubit.state.resumo.alertasBoletos, isEmpty);
    });

    test('lembrete abre o WhatsApp com a mensagem de recompra', () async {
      final ambiente = _comTudo();
      await ambiente.consultora.buscarMinha();
      final cubit = ambiente.cubit(DateTime.now());
      addTearDown(cubit.close);
      await pumpEventQueue();

      await cubit.lembrarRecompra(cubit.state.resumo.lembretes.single);
      expect(ambiente.whatsapp.aberturas, ['11987654321']);
      expect(ambiente.whatsapp.mensagens.single, contains('Já faz 62 dias'));
      expect(ambiente.whatsapp.mensagens.single, endsWith('Ana'));
    });

    test('erro de rede mostra a mensagem', () async {
      final ambiente = _comTudo()..servicoInicio.falharRede = true;
      final cubit = ambiente.cubit(DateTime.now());
      addTearDown(cubit.close);
      await pumpEventQueue();
      expect(cubit.state.mensagemErro, contains('Sem conexão'));
    });
  });

  group('Início (tela)', () {
    testWidgets('números, alertas e lembrete', (tester) async {
      await _abrir(tester, _comTudo());

      expect(find.textContaining(', Ana!'), findsOneWidget);
      expect(find.text('Vendido no mês'), findsOneWidget);
      expect(find.text('R\$ 3.840,00'), findsOneWidget);
      expect(find.text('pedido feito'), findsOneWidget);
      expect(find.text('R\$ 2.450'), findsOneWidget);
      expect(find.text('Alertas de hoje'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('VENCE AMANHÃ'), findsOneWidget);
      expect(find.text('R\$ 842,50'), findsOneWidget);
      expect(find.text('2 CLIENTES'), findsOneWidget);
      expect(find.text('Total R\$ 280,00'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Acabando!'), 200);
      expect(find.text('Dona Carla'), findsOneWidget);
      expect(find.text('Lily Eau de Parfum 75ml • há 62 dias'), findsOneWidget);
    });

    // Os finders são criados dentro do teste (os de acessibilidade precisam
    // dele ligado).
    for (final (rotulo, alvo, destino) in <(String, Finder Function(), String)>[
      ('Ver fatura', () => find.text('Ver fatura'), 'boleto b1'),
      ('Cobrar agora', () => find.text('Cobrar agora'), 'a receber atrasado'),
      (
        'Recebido',
        () => find.bySemanticsLabel(RegExp('^Recebido')),
        'a receber pago',
      ),
      ('Vendas', () => find.bySemanticsLabel(RegExp('^Vendas:')), 'vendas'),
      ('Boletos', () => find.bySemanticsLabel(RegExp('^Boletos:')), 'a pagar'),
      ('Ver todos', () => find.text('Ver todos'), 'clientes'),
    ]) {
      testWidgets('$rotulo abre $destino', (tester) async {
        await _abrir(tester, _comTudo());
        // A lista só monta o que está perto da tela: rola até o alvo.
        if (alvo().hitTestable().evaluate().isEmpty) {
          await tester.scrollUntilVisible(alvo().hitTestable(), 150);
        }
        await tester.tap(alvo().hitTestable().first);
        await tester.pumpAndSettle();
        expect(find.text(destino), findsOneWidget);
      });
    }

    testWidgets('ícone de conversa do lembrete abre o WhatsApp', (
      tester,
    ) async {
      final ambiente = _comTudo();
      await _abrir(tester, ambiente);
      final botao = find.byTooltip('Lembrar Dona Carla no WhatsApp');
      await tester.scrollUntilVisible(botao.hitTestable(), 150);
      await tester.tap(botao.hitTestable());
      await tester.pumpAndSettle();
      expect(ambiente.whatsapp.mensagens.single, contains('Lily'));
    });

    testWidgets('sem nada: Nada para hoje e lembrete vazio', (tester) async {
      await _abrir(tester, _Ambiente());
      expect(find.text('Nada para hoje'), findsOneWidget);
      expect(find.text('R\$ 0,00'), findsOneWidget);
      expect(
        find.textContaining('Nenhuma cliente precisando recomprar'),
        findsOneWidget,
      );
    });
  });
}
