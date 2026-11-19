// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/model/forma_pagamento.dart';
import 'package:sou_consultora/core/model/item_venda.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/core/repository/repositorio_servicos.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/clientes/compras/clientes_compras_screen.dart';
import 'package:sou_consultora/ui/modules/vendas/detalhes/vendas_detalhes_cubit.dart';
import 'package:sou_consultora/ui/modules/vendas/detalhes/vendas_detalhes_screen.dart';
import 'package:sou_consultora/ui/modules/vendas/lista/vendas_lista_screen.dart';
import 'package:sou_consultora/ui/modules/vendas/nova/nova_venda_cubit.dart';
import 'package:sou_consultora/ui/modules/vendas/nova/nova_venda_screen.dart';

import '../../auxiliares/falsos_clientes.dart';
import '../../auxiliares/falsos_consultora.dart';
import '../../auxiliares/falsos_produtos.dart';
import '../../auxiliares/falsos_servicos.dart';
import '../../auxiliares/falsos_vendas.dart';
import '../../auxiliares/montar_app.dart';

class _Ambiente {
  _Ambiente({ServicoVendasFalso? servico})
    : servicoVendas = servico ?? ServicoVendasFalso(),
      produtos = repositorioProdutosDeTeste(
        ServicoProdutosFalso(
          resumos: [
            produtoDto('p1', 'Kit Lily', precoVenda: 19600, qtdDisponivel: 2),
          ],
        ),
      ),
      clientes = repositorioClientesDeTeste(
        ServicoClientesFalso(resumos: [resumoDto('c1', 'Camila Rodrigues')]),
      ),
      servicos = repositorioServicosDeTeste(
        ServicoServicosFalso(
          resumos: [servicoDto('s1', 'Design de Sobrancelha', preco: 4500)],
        ),
      ),
      whatsapp = ServicoWhatsappFalso() {
    vendas = repositorioVendasDeTeste(
      servicoVendas,
      produtos: produtos,
      clientes: clientes,
      whatsapp: whatsapp,
    );
  }

  final ServicoVendasFalso servicoVendas;
  final RepositorioProdutos produtos;
  final RepositorioClientes clientes;
  final RepositorioServicos servicos;
  final ServicoWhatsappFalso whatsapp;
  late final RepositorioVendas vendas;

  void registrar() {
    final consultora = repositorioDeTeste(
      ServicoConsultoraFalso(
        registro: dtoDeTeste(chave: 'ana@email.com', tipo: 'email'),
      ),
    );
    injetor
      ..registerSingleton<RepositorioVendas>(vendas)
      ..registerSingleton<RepositorioProdutos>(produtos)
      ..registerSingleton<RepositorioClientes>(clientes)
      ..registerSingleton<RepositorioServicos>(servicos)
      ..registerSingleton<RepositorioConsultora>(consultora);
  }
}

Future<void> _abrir(
  WidgetTester tester,
  _Ambiente ambiente,
  String caminho,
) async {
  usarTelaDeCelular(tester);
  ambiente.registrar();
  await injetor<RepositorioConsultora>().buscarMinha();
  final roteador = GoRouter(
    initialLocation: '/inicio',
    routes: [
      GoRoute(
        path: '/inicio',
        builder: (_, _) => const Scaffold(body: Text('anterior')),
      ),
      GoRoute(
        path: '/vendas',
        builder: (_, _) => const Scaffold(body: VendasListaScreen()),
      ),
      GoRoute(
        path: '/vendas/nova',
        builder: (_, e) =>
            NovaVendaScreen(clienteInicialId: e.uri.queryParameters['cliente']),
      ),
      GoRoute(
        path: '/vendas/:id',
        builder: (_, e) =>
            VendasDetalhesScreen(idVenda: e.pathParameters['id']!),
      ),
      GoRoute(
        path: '/vendas/:id/editar',
        builder: (_, e) => NovaVendaScreen(idVenda: e.pathParameters['id']),
      ),
      GoRoute(
        path: '/clientes/:id/compras',
        builder: (_, e) =>
            ClientesComprasScreen(idCliente: e.pathParameters['id']!),
      ),
      GoRoute(
        path: '/a-receber/parcelas/:id',
        builder: (_, _) => const Scaffold(body: Text('parcela')),
      ),
    ],
  );
  addTearDown(() async {
    roteador.dispose();
    await injetor.reset();
  });
  await tester.pumpWidget(appDeTeste(roteador: roteador));
  await tester.pumpAndSettle();
  roteador.push(caminho);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('Nova venda (cubit)', () {
    late _Ambiente ambiente;
    late NovaVendaCubit cubit;

    setUp(() async {
      ambiente = _Ambiente();
      cubit = NovaVendaCubit(
        clienteInicialId: 'c1',
        vendas: ambiente.vendas,
        clientes: ambiente.clientes,
        produtos: ambiente.produtos,
        servicos: ambiente.servicos,
        agora: () => DateTime(2026, 11, 17, 10),
      );
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() => cubit.close());

    ItemPedido item({int desconto = 0}) => ItemPedido(
      tipo: TipoItem.produto,
      catalogoId: 'p1',
      nome: 'Kit Lily',
      precoUnitario: 19600,
      quantidade: 1,
      desconto: desconto,
      saldoEstoque: 2,
    );

    test('avançar exige itens; repetido é recusado', () {
      cubit.avancar();
      expect(cubit.state.passo, 1);
      expect(
        cubit.state.aviso?.mensagem,
        'Adicione pelo menos um produto ou serviço',
      );
      expect(cubit.state.erroItens, isNull);

      cubit
        ..adicionarItem(item(desconto: 1600))
        ..adicionarItem(item());
      expect(cubit.state.itens.length, 1);
      expect(cubit.state.aviso?.mensagem, 'Este item já está no pedido.');
      expect(cubit.state.total, 18000);
    });

    test(
      'dividido sugere parcelas; soma diferente bloqueia; conclui',
      () async {
        cubit
          ..adicionarItem(item())
          ..avancar();
        expect(cubit.state.passo, 2);
        expect(cubit.state.parcelas.single.valor, 19600);

        cubit
          ..escolherAVista(false)
          ..alterarQtdParcelas(3);
        expect(cubit.state.parcelas.map((p) => p.valor), [6533, 6533, 6534]);
        expect(cubit.state.parcelas[1].vencimento, DateTime(2026, 12, 17));

        cubit.alterarValorParcela(0, 6000);
        expect(cubit.state.diferenca, 533);
        expect(cubit.state.podeConcluir, isFalse);

        cubit
          ..alterarQtdParcelas(2)
          ..alterarEntrada(true)
          ..alterarFormaEntrada(FormaPagamento.dinheiro);
        await cubit.concluir();
        final pedido = ambiente.servicoVendas.concluidos.single;
        expect(pedido.parcelas.length, 2);
        expect(pedido.entrada, FormaPagamento.dinheiro);
        expect(cubit.state.idSalvo, isNotNull);
      },
    );

    test('data futura bloqueia', () {
      cubit
        ..adicionarItem(item())
        ..avancar()
        ..alterarDataVenda(DateTime(2026, 11, 18));
      expect(cubit.state.erroData, isNotNull);
      expect(cubit.state.podeConcluir, isFalse);
    });
  });

  group('Nova venda (tela)', () {
    testWidgets('sem item, avançar mostra o aviso', (tester) async {
      await _abrir(tester, _Ambiente(), '/vendas/nova?cliente=c1');

      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Adicione pelo menos um produto ou serviço'),
        findsOneWidget,
      );
      expect(find.text('Como a cliente vai pagar?'), findsNothing);
    });

    testWidgets('folha: estoque insuficiente avisa no Salvar; sem baixar libera', (
      tester,
    ) async {
      final ambiente = _Ambiente();
      await _abrir(tester, ambiente, '/vendas/nova?cliente=c1');
      expect(find.text('Camila Rodrigues'), findsOneWidget);

      await tester.tap(find.text('Adicionar Produto ou Serviço'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escolha o produto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kit Lily').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Aumentar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Aumentar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Aumentar'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Baixar do estoque'));
      await tester.pumpAndSettle();
      // O erro sai em toast, ao tocar em Salvar; a folha continua aberta.
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Estoque insuficiente: 2 un disponíveis'),
        findsOneWidget,
      );
      expect(find.text('Baixar do estoque'), findsOneWidget);

      await tester.ensureVisible(find.text('Baixar do estoque'));
      await tester.tap(find.text('Baixar do estoque'));
      // O toast do erro fica um tempo na tela antes de sumir sozinho.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Estoque insuficiente: 2 un disponíveis'), findsNothing);

      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Encomenda'), findsNothing);
      expect(find.text(FormatadorMoeda.formatar(58800)), findsWidgets);

      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();
      expect(find.text('Como a cliente vai pagar?'), findsOneWidget);
      await tester.ensureVisible(find.text('Concluir Venda'));
      await tester.tap(find.text('Concluir Venda'));
      await tester.pumpAndSettle();
      expect(find.text('anterior'), findsOneWidget);
      expect(
        ambiente.servicoVendas.concluidos.single.itens.single.baixarEstoque,
        isFalse,
      );
    });
  });

  group('Lista', () {
    testWidgets('contador, busca pelo código e abre o detalhe', (tester) async {
      final ambiente = _Ambiente(
        servico: ServicoVendasFalso(
          vendas: [
            vendaDto('v1', codigo: 12, cliente: 'Camila Rodrigues'),
            vendaDto('v2', codigo: 13, cliente: 'Juliana Peixoto', pago: 24000),
          ],
        ),
      );
      await _abrir(tester, ambiente, '/vendas');

      expect(find.text('2 vendas'), findsOneWidget);
      expect(find.text('Nova venda'), findsOneWidget);
      expect(find.text('Quitada'), findsOneWidget);
      await tester.enterText(find.byType(EditableText).first, '12');
      await tester.pumpAndSettle();
      expect(find.text('1 venda'), findsOneWidget);
      expect(find.text('Juliana Peixoto'), findsNothing);
    });

    testWidgets('vazia convida a registrar', (tester) async {
      await _abrir(tester, _Ambiente(), '/vendas');
      expect(find.text('Nenhuma venda ainda'), findsOneWidget);
      expect(find.text('Registrar venda'), findsOneWidget);
      expect(find.text('Nova venda'), findsNothing);
    });
  });

  group('Detalhes', () {
    _Ambiente comVenda({int pago = 0}) => _Ambiente(
      servico: ServicoVendasFalso(
        vendas: [vendaDto('v1', codigo: 12, pago: pago, total: 24000)],
        itens: [
          itemDto('v1', 'Kit Lily', preco: 18000),
          itemDto('v1', 'Design de Sobrancelhas', servicoId: 's1', preco: 6000),
        ],
        parcelas: [
          parcelaDto(
            'pa1',
            'v1',
            valor: 12000,
            qtd: 2,
            pago: pago > 0 ? 12000 : 0,
          ),
          parcelaDto('pa2', 'v1', numero: 2, qtd: 2, valor: 12000),
        ],
      ),
    );

    testWidgets('itens, parcelas e editar só sem pagamento', (tester) async {
      await _abrir(tester, comVenda(), '/vendas/v1');
      expect(find.text('Itens 2'), findsOneWidget);
      expect(find.text('Design de Sobrancelhas'), findsOneWidget);
      expect(find.text('Editar Venda'), findsOneWidget);

      await tester.tap(find.text('Pagamento 2'));
      await tester.pumpAndSettle();
      expect(find.text('Parcela 1 de 2'), findsOneWidget);
      expect(find.text('Parcela 2 de 2'), findsOneWidget);
    });

    testWidgets('com pagamento não edita; cancelar pede confirmação', (
      tester,
    ) async {
      final ambiente = comVenda(pago: 12000);
      await _abrir(tester, ambiente, '/vendas/v1');
      expect(find.text('Editar Venda'), findsNothing);

      await tester.tap(find.text('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar Venda'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('devolve os produtos ao estoque'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancelar venda'));
      await tester.pumpAndSettle();
      expect(ambiente.servicoVendas.cancelados, ['v1']);
      expect(find.text('anterior'), findsOneWidget);
    });

    test('cobrar abre o WhatsApp com a mensagem da próxima parcela', () async {
      final ambiente = comVenda(pago: 12000);
      final consultora = repositorioDeTeste(
        ServicoConsultoraFalso(
          registro: dtoDeTeste(chave: 'ana@email.com', tipo: 'email'),
        ),
      );
      await consultora.buscarMinha();
      final cubit = VendasDetalhesCubit(
        idVenda: 'v1',
        vendas: ambiente.vendas,
        consultora: consultora,
      );
      await Future<void>.delayed(Duration.zero);

      await cubit.cobrar();

      final mensagem = ambiente.whatsapp.mensagens.single!;
      expect(mensagem, contains('parcela 2 de 2'));
      expect(mensagem, contains('ana@email.com'));
      await cubit.close();
    });
  });

  group('Compras da cliente', () {
    testWidgets('totais, compras e nova venda', (tester) async {
      final ambiente = _Ambiente(
        servico: ServicoVendasFalso(
          vendas: [vendaDto('v1', codigo: 12, itens: 'Kit Lily', pago: 24000)],
          parcelas: [parcelaDto('pa1', 'v1', valor: 24000, pago: 24000)],
        ),
      );
      await _abrir(tester, ambiente, '/clientes/c1/compras');

      expect(find.text('Camila Rodrigues'), findsOneWidget);
      expect(find.text('1 quitada'), findsOneWidget);
      expect(find.text('Kit Lily'), findsOneWidget);
      expect(find.text('Nova Venda'), findsOneWidget);
      expect(find.text('Registrar venda'), findsNothing);
    });

    testWidgets('sem compras: registrar no vazio e sem o botão de baixo', (
      tester,
    ) async {
      await _abrir(tester, _Ambiente(), '/clientes/c1/compras');

      expect(find.text('Nenhuma compra ainda'), findsOneWidget);
      expect(find.text('Registrar venda'), findsOneWidget);
      expect(find.text('Nova Venda'), findsNothing);
    });
  });
}
