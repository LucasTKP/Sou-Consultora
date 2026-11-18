// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/model/detalhe_parcela.dart';
import 'package:sou_consultora/core/model/filtro_recebimentos.dart';
import 'package:sou_consultora/core/model/forma_pagamento.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/core/repository/repositorio_recebimentos.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/mensagem_comprovante.dart';
import 'package:sou_consultora/ui/modules/a_receber/comprovante/a_receber_comprovante_screen.dart';
import 'package:sou_consultora/ui/modules/a_receber/lista/a_receber_lista_cubit.dart';
import 'package:sou_consultora/ui/modules/a_receber/lista/a_receber_lista_screen.dart';
import 'package:sou_consultora/ui/modules/a_receber/parcela/a_receber_parcela_cubit.dart';
import 'package:sou_consultora/ui/modules/a_receber/parcela/a_receber_parcela_screen.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';

import '../../auxiliares/falsos_clientes.dart';
import '../../auxiliares/falsos_consultora.dart';
import '../../auxiliares/falsos_produtos.dart';
import '../../auxiliares/falsos_recebimentos.dart';
import '../../auxiliares/falsos_vendas.dart';
import '../../auxiliares/montar_app.dart';

class _Ambiente {
  _Ambiente({ServicoVendasFalso? vendas})
    : servicoVendas = vendas ?? ServicoVendasFalso(),
      produtos = repositorioProdutosDeTeste(ServicoProdutosFalso()),
      clientes = repositorioClientesDeTeste(
        ServicoClientesFalso(resumos: [resumoDto('c1', 'Mariana Souza')]),
      ),
      whatsapp = ServicoWhatsappFalso(),
      compartilhar = ServicoCompartilharFalso() {
    servicoRecebimentos = ServicoRecebimentosFalso(vendas: servicoVendas);
    repositorioVendas = repositorioVendasDeTeste(
      servicoVendas,
      produtos: produtos,
      clientes: clientes,
      whatsapp: whatsapp,
    );
    recebimentos = repositorioRecebimentosDeTeste(
      vendas: servicoVendas,
      recebimentos: servicoRecebimentos,
      repositorioVendas: repositorioVendas,
      clientes: clientes,
      compartilhar: compartilhar,
    );
  }

  final ServicoVendasFalso servicoVendas;
  late final ServicoRecebimentosFalso servicoRecebimentos;
  final RepositorioProdutos produtos;
  final RepositorioClientes clientes;
  final ServicoWhatsappFalso whatsapp;
  final ServicoCompartilharFalso compartilhar;
  late final RepositorioVendas repositorioVendas;
  late final RepositorioRecebimentos recebimentos;

  /// Abre a tela real de detalhes da parcela (a lista usa um marcador).
  bool parcelaDeVerdade = false;

  /// Abre a tela real do comprovante (os detalhes usam um marcador).
  bool comprovanteDeVerdade = false;

  void registrar() {
    final consultora = repositorioDeTeste(
      ServicoConsultoraFalso(
        registro: dtoDeTeste(
          nome: 'Ana Paula Silva',
          chave: 'ana@email.com',
          tipo: 'email',
        ),
      ),
    );
    injetor
      ..registerSingleton<RepositorioRecebimentos>(recebimentos)
      ..registerSingleton<RepositorioVendas>(repositorioVendas)
      ..registerSingleton<RepositorioProdutos>(produtos)
      ..registerSingleton<RepositorioClientes>(clientes)
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
        path: '/a-receber',
        builder: (_, _) => const Scaffold(body: AReceberListaScreen()),
      ),
      GoRoute(
        path: '/a-receber/parcelas/:id',
        builder: (_, e) => ambiente.parcelaDeVerdade
            ? AReceberParcelaScreen(idParcela: e.pathParameters['id']!)
            : Scaffold(body: Text('parcela ${e.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/a-receber/parcelas/:id/comprovante',
        builder: (_, e) => ambiente.comprovanteDeVerdade
            ? AReceberComprovanteScreen(
                idParcela: e.pathParameters['id']!,
                idPagamento: e.uri.queryParameters['pagamento'],
              )
            : Scaffold(
                body: Text(
                  'comprovante ${e.pathParameters['id']} '
                  '${e.uri.queryParameters['pagamento']}',
                ),
              ),
      ),
      GoRoute(
        path: '/vendas/:id',
        builder: (_, e) =>
            Scaffold(body: Text('venda ${e.pathParameters['id']}')),
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

  group('Lista (cubit)', () {
    final hoje = DateTime(2026, 11, 17, 9);

    test('contagens, status e todos os meses', () async {
      final ambiente = _Ambiente(
        vendas: ServicoVendasFalso(
          parcelas: [
            parcelaDto('atrasada', 'v1', vencimento: DateTime(2026, 11, 10)),
            parcelaDto('hoje', 'v2', vencimento: DateTime(2026, 11, 17)),
            parcelaDto('futura', 'v3', vencimento: DateTime(2026, 11, 25)),
            parcelaDto(
              'paga',
              'v4',
              vencimento: DateTime(2026, 11, 5),
              pago: 24000,
            ),
            parcelaDto('dezembro', 'v5', vencimento: DateTime(2026, 12, 5)),
          ],
        ),
      );
      final cubit = AReceberListaCubit(
        repositorio: ambiente.recebimentos,
        agora: () => hoje,
      );
      addTearDown(cubit.close);
      await pumpEventQueue();

      final contagens = cubit.state.contagens;
      expect(contagens[StatusFiltroRecebimento.todos], 4);
      expect(contagens[StatusFiltroRecebimento.aReceber], 1);
      expect(contagens[StatusFiltroRecebimento.atrasado], 1);
      expect(contagens[StatusFiltroRecebimento.venceHoje], 1);
      expect(contagens[StatusFiltroRecebimento.pago], 1);

      cubit.alterarStatus(StatusFiltroRecebimento.atrasado);
      expect(cubit.state.visiveis.map((p) => p.id), ['atrasada']);

      cubit
        ..alterarStatus(StatusFiltroRecebimento.aReceber)
        ..alterarMes(null);
      expect(cubit.state.visiveis.map((p) => p.id), ['futura', 'dezembro']);
    });

    test('erro de rede mostra a mensagem', () async {
      final ambiente = _Ambiente()..servicoVendas.falharRede = true;
      final cubit = AReceberListaCubit(
        repositorio: ambiente.recebimentos,
        agora: () => hoje,
      );
      addTearDown(cubit.close);
      await pumpEventQueue();
      expect(cubit.state.mensagemErro, contains('Sem conexão'));
    });
  });

  group('Lista (tela)', () {
    testWidgets('cards, busca pelo produto e abre a parcela', (tester) async {
      final hoje = DateTime.now();
      final ambiente = _Ambiente(
        vendas: ServicoVendasFalso(
          parcelas: [
            parcelaDto(
              'pa1',
              'v1',
              numero: 2,
              qtd: 2,
              valor: 12000,
              pago: 5000,
              vencimento: hoje,
              cliente: 'Mariana Souza',
              itens: 'Kit Lily',
            ),
            parcelaDto(
              'pa2',
              'v2',
              valor: 8000,
              vencimento: hoje,
              cliente: 'Beatriz Lima',
              itens: 'Batom Matte',
            ),
            // Mês que vem: fora do filtro padrão (mês atual).
            parcelaDto(
              'pa3',
              'v3',
              vencimento: DateTime(hoje.year, hoje.month + 1, 15),
              cliente: 'Fora do Mês',
            ),
          ],
        ),
      );
      await _abrir(tester, ambiente, '/a-receber');

      expect(find.text('Recebimentos'), findsOneWidget);
      expect(find.text('2 parcelas encontradas'), findsOneWidget);
      expect(find.text('Fora do Mês'), findsNothing);
      expect(find.text('Vence hoje'), findsNWidgets(2));
      expect(find.text('Parcela 2/2 • R\$ 70,00'), findsOneWidget);
      expect(find.text('Parcela única • R\$ 80,00'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).first, 'lily');
      await tester.pumpAndSettle();
      expect(find.text('1 parcela encontrada'), findsOneWidget);
      expect(find.text('Beatriz Lima'), findsNothing);

      await tester.tap(find.text('Mariana Souza'));
      await tester.pumpAndSettle();
      expect(find.text('parcela pa1'), findsOneWidget);
    });

    testWidgets('sem parcelas mostra o vazio', (tester) async {
      await _abrir(tester, _Ambiente(), '/a-receber');
      expect(find.text('Nada a receber'), findsOneWidget);
    });
  });

  group('Detalhes da parcela', () {
    /// Venda v1 em 2x de R\$ 120,00; a 2ª recebeu R\$ 50,00 no Pix.
    _Ambiente parcial({DateTime? vencimento}) {
      final venc = vencimento ?? DateTime.now().add(const Duration(days: 5));
      final vendas = ServicoVendasFalso(
        vendas: [vendaDto('v1', codigo: 4892, total: 24000, pago: 17000)],
        parcelas: [
          parcelaDto(
            'pa1',
            'v1',
            qtd: 2,
            valor: 12000,
            pago: 12000,
            codigo: 4892,
          ),
          parcelaDto(
            'pa2',
            'v1',
            numero: 2,
            qtd: 2,
            valor: 12000,
            pago: 5000,
            vencimento: venc,
            codigo: 4892,
          ),
        ],
      );
      final ambiente = _Ambiente(vendas: vendas)..parcelaDeVerdade = true;
      final antes = DateTime.now().subtract(const Duration(days: 3));
      ambiente.servicoRecebimentos.pagamentos = [
        pagamentoDto('pg1', 'pa1', 'v1', valor: 12000, data: antes),
        pagamentoDto('pg2', 'pa2', 'v1', valor: 5000, data: antes),
      ];
      return ambiente;
    }

    AReceberParcelaCubit cubitDe(_Ambiente ambiente, DateTime hoje) {
      ambiente.registrar();
      final cubit = AReceberParcelaCubit(
        idParcela: 'pa2',
        recebimentos: ambiente.recebimentos,
        vendas: ambiente.repositorioVendas,
        agora: () => hoje,
      );
      addTearDown(() async {
        await cubit.close();
        await injetor.reset();
      });
      return cubit;
    }

    test('valida valor e data antes de gravar', () async {
      final hoje = DateTime.now();
      final ambiente = parcial();
      final cubit = cubitDe(ambiente, hoje);
      await pumpEventQueue();
      expect(cubit.state.detalhe?.parcela.saldo, 7000);

      Future<String?> pagar(int valor, {DateTime? data}) =>
          cubit.registrarPagamento(
            valorCentavos: valor,
            forma: FormaPagamento.pix,
            data: data ?? hoje,
          );

      expect(await pagar(8000), isNull);
      expect(cubit.state.erroValor, contains('saldo'));
      expect(await pagar(0), isNull);
      expect(cubit.state.erroValor, 'Informe o valor recebido');
      expect(
        await pagar(3000, data: hoje.add(const Duration(days: 1))),
        isNull,
      );
      expect(cubit.state.erroData, contains('futuro'));
      expect(ambiente.servicoRecebimentos.pagamentos, hasLength(2));

      expect(await pagar(3000), 'pg-1');
      expect(cubit.state.erroValor, isNull);
      expect(cubit.state.detalhe?.parcela.saldo, 4000);
      expect(cubit.state.detalhe?.pagamentos.first.valor, 3000);
    });

    test('erro do servidor aparece na folha', () async {
      final ambiente = parcial();
      ambiente.servicoRecebimentos.falhaAoRegistrar = const FalhaValidacao(
        'O valor passa do saldo da parcela (R\$ 70,00).',
      );
      final cubit = cubitDe(ambiente, DateTime.now());
      await pumpEventQueue();
      final gravou = await cubit.registrarPagamento(
        valorCentavos: 7000,
        forma: FormaPagamento.pix,
        data: DateTime.now(),
      );
      expect(gravou, isNull);
      expect(cubit.state.erroPagamento, contains('saldo'));
      expect(cubit.state.registrando, isFalse);
    });

    testWidgets('pagamento parcial: saldo, pagamentos e a venda', (
      tester,
    ) async {
      final ambiente = parcial(
        vencimento: DateTime.now().subtract(const Duration(days: 18)),
      );
      await _abrir(tester, ambiente, '/a-receber/parcelas/pa2');

      expect(find.text('PARCELA 2 DE 2'), findsOneWidget);
      expect(find.text('R\$ 70,00'), findsWidgets);
      expect(find.text('Pago R\$ 50,00'), findsOneWidget);
      expect(find.text('Resta R\$ 70,00'), findsOneWidget);
      expect(find.text('há 18 dias'), findsOneWidget);
      expect(find.text('(11) 98765-4321'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.textContaining('Saldo restante • venceu'),
        200,
      );
      expect(find.textContaining('Via Pix'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Você está aqui'), 200);
      expect(find.text('Venda #4892'), findsOneWidget);
      expect(find.text('PARCELAS DA VENDA (2X)'), findsOneWidget);

      await tester.tap(find.text('1ª parcela • R\$ 120,00'));
      await tester.pumpAndSettle();
      expect(find.text('PARCELA 1 DE 2'), findsOneWidget);
      expect(find.text('PARCELA QUITADA'), findsOneWidget);
      expect(find.text('Pagar'), findsNothing);
    });

    testWidgets('Pagar: recusa valor acima do saldo e abre o comprovante', (
      tester,
    ) async {
      final ambiente = parcial();
      await _abrir(tester, ambiente, '/a-receber/parcelas/pa2');

      await tester.tap(find.text('Pagar'));
      await tester.pumpAndSettle();
      expect(find.text('Registrar pagamento'), findsOneWidget);
      expect(find.text('Saldo da parcela: R\$ 70,00'), findsOneWidget);
      final valor = find.descendant(
        of: find.byType(CampoMoedaApp),
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(valor).controller.text, '70,00');

      await tester.enterText(valor, '8000');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(
        find.text('O valor não pode passar do saldo da parcela'),
        findsOneWidget,
      );
      expect(ambiente.servicoRecebimentos.pagamentos, hasLength(2));

      await tester.enterText(valor, '7000');
      await tester.tap(find.text('Dinheiro'));
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(find.text('comprovante pa2 pg-1'), findsOneWidget);
      final novo = ambiente.servicoRecebimentos.pagamentos.first;
      expect(novo.valor, 7000);
      expect(novo.formaPagamento, 'dinheiro');
    });

    testWidgets('Cobrar abre o WhatsApp com a mensagem da parcela', (
      tester,
    ) async {
      final ambiente = parcial();
      await _abrir(tester, ambiente, '/a-receber/parcelas/pa2');

      await tester.tap(find.text('Cobrar'));
      await tester.pumpAndSettle();
      final mensagem = ambiente.whatsapp.mensagens.single!;
      expect(mensagem, contains('parcela 2 de 2'));
      expect(mensagem, contains('R\$ 70,00'));
    });

    testWidgets('Mais opções: cancelar a venda fecha a tela', (tester) async {
      final ambiente = parcial();
      await _abrir(tester, ambiente, '/a-receber/parcelas/pa2');

      await tester.tap(find.text('Mais opções'));
      await tester.pumpAndSettle();
      expect(find.text('Gerar Recibo / Comprovante'), findsOneWidget);
      await tester.tap(find.text('Cancelar Venda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar venda'));
      await tester.pumpAndSettle();
      expect(ambiente.servicoVendas.cancelados, ['v1']);
      expect(find.text('anterior'), findsOneWidget);
    });

    testWidgets('parcela inexistente mostra o erro', (tester) async {
      final ambiente = parcial();
      await _abrir(tester, ambiente, '/a-receber/parcelas/nao-existe');
      expect(find.text('Parcela não encontrada.'), findsOneWidget);
    });
  });

  group('Comprovante', () {
    /// Venda v1 em 2x de R$ 120,00: a 1ª paga; a 2ª quitada agora no Pix
    /// (R$ 50,00 há 3 dias + R$ 70,00 hoje).
    _Ambiente quitada() {
      final antes = DateTime.now().subtract(const Duration(days: 3));
      final vendas = ServicoVendasFalso(
        vendas: [vendaDto('v1', codigo: 4892, total: 24000, pago: 24000)],
        parcelas: [
          parcelaDto(
            'pa1',
            'v1',
            qtd: 2,
            valor: 12000,
            pago: 12000,
            codigo: 4892,
          ),
          parcelaDto(
            'pa2',
            'v1',
            numero: 2,
            qtd: 2,
            valor: 12000,
            pago: 12000,
            codigo: 4892,
            cliente: 'Carla Menezes',
          ),
        ],
      );
      final ambiente = _Ambiente(vendas: vendas)
        ..parcelaDeVerdade = true
        ..comprovanteDeVerdade = true;
      ambiente.servicoRecebimentos.pagamentos = [
        pagamentoDto('pg3', 'pa2', 'v1', valor: 7000, data: DateTime.now()),
        pagamentoDto('pg2', 'pa2', 'v1', valor: 5000, data: antes),
        pagamentoDto('pg1', 'pa1', 'v1', valor: 12000, data: antes),
      ];
      return ambiente;
    }

    Future<void> tocarCompartilhar(WidgetTester tester) async {
      // Gerar o PNG usa o motor de verdade: roda fora do relógio falso.
      await tester.runAsync(() async {
        await tester.tap(find.text('Compartilhar'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
    }

    testWidgets('mostra o último pagamento, a venda e o saldo', (tester) async {
      await _abrir(tester, quitada(), '/a-receber/parcelas/pa2/comprovante');

      expect(find.text('Pagamento confirmado'), findsOneWidget);
      expect(find.text(r'R$ 70,00'), findsWidgets);
      expect(find.text('Ana Paula Silva'), findsOneWidget);
      expect(find.text('ana@email.com'), findsOneWidget);
      expect(find.text('Carla Menezes'), findsOneWidget);
      expect(find.text('Pix'), findsOneWidget);
      expect(find.text('Parcela 2 de 2 • Quitada'), findsOneWidget);
      expect(find.text('Venda #4892'), findsOneWidget);
      expect(find.text('Parcela 2 de 2 • este pagamento'), findsOneWidget);
      expect(find.textContaining('Parcela 1 de 2 • paga em'), findsOneWidget);
      expect(find.text('Saldo restante da venda'), findsOneWidget);
      expect(find.text(r'R$ 0,00'), findsOneWidget);
    });

    testWidgets('pelo id mostra o pagamento pedido (não o mais recente)', (
      tester,
    ) async {
      await _abrir(
        tester,
        quitada(),
        '/a-receber/parcelas/pa2/comprovante?pagamento=pg2',
      );
      expect(find.text(r'R$ 50,00'), findsWidgets);
      expect(find.text(r'R$ 70,00'), findsNothing);
    });

    testWidgets('Compartilhar envia a imagem e o texto curto', (tester) async {
      final ambiente = quitada();
      await _abrir(tester, ambiente, '/a-receber/parcelas/pa2/comprovante');
      await tocarCompartilhar(tester);

      final enviado = ambiente.compartilhar.compartilhados.single;
      expect(enviado.nomeArquivo, 'comprovante.png');
      // Assinatura de PNG.
      expect(enviado.png.sublist(1, 4), 'PNG'.codeUnits);
      expect(enviado.texto, contains('Carla Menezes'));
      expect(enviado.texto, contains(r'R$ 70,00 via Pix'));
      expect(enviado.texto, contains('Parcela 2 de 2 • Quitada'));
      expect(enviado.texto, contains(r'Saldo restante da venda: R$ 0,00'));
    });

    testWidgets('falha ao compartilhar avisa', (tester) async {
      final ambiente = quitada()..compartilhar.falhar = true;
      await _abrir(tester, ambiente, '/a-receber/parcelas/pa2/comprovante');
      await tocarCompartilhar(tester);
      expect(find.text('Não foi possível compartilhar.'), findsOneWidget);
    });

    testWidgets('parcela sem pagamento mostra o aviso', (tester) async {
      final ambiente = quitada();
      ambiente.servicoRecebimentos.pagamentos = [];
      await _abrir(tester, ambiente, '/a-receber/parcelas/pa2/comprovante');
      expect(
        find.text('Esta parcela ainda não tem pagamento.'),
        findsOneWidget,
      );
    });

    testWidgets('pagamento retroativo: o comprovante é o recém-gravado', (
      tester,
    ) async {
      final hoje = DateTime.now();
      final ambiente =
          _Ambiente(
              vendas: ServicoVendasFalso(
                vendas: [vendaDto('v1', total: 12000, pago: 5000)],
                parcelas: [parcelaDto('pa1', 'v1', valor: 12000, pago: 5000)],
              ),
            )
            ..parcelaDeVerdade = true
            ..comprovanteDeVerdade = true;
      ambiente.servicoRecebimentos.pagamentos = [
        pagamentoDto('pg0', 'pa1', 'v1', valor: 5000, data: hoje),
      ];
      await _abrir(tester, ambiente, '/a-receber/parcelas/pa1');

      await tester.tap(find.text('Pagar'));
      await tester.pumpAndSettle();
      final valor = find.descendant(
        of: find.byType(CampoMoedaApp),
        matching: find.byType(EditableText),
      );
      await tester.enterText(valor, '3000');
      // Ontem pelo calendário.
      await tester.tap(find.text(FormatadorData.curta(hoje)));
      await tester.pumpAndSettle();
      final ontem = hoje.subtract(const Duration(days: 1));
      if (ontem.month != hoje.month) {
        await tester.tap(find.byTooltip('Mês anterior'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('${ontem.day}').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text(FormatadorData.curta(ontem)), findsOneWidget);
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Pagamento confirmado'), findsOneWidget);
      expect(find.text(r'R$ 30,00'), findsWidgets);
      expect(find.text('Parcela 1 de 1 • Parcial'), findsOneWidget);
    });

    test('texto curto da parcela parcial', () {
      final venda = vendaDto('v1', total: 12000).paraModel();
      final parcela = parcelaDto(
        'pa1',
        'v1',
        valor: 12000,
        pago: 5000,
        cliente: 'Carla Menezes',
      ).paraModel();
      final pagamento = pagamentoDto(
        'pg1',
        'pa1',
        'v1',
        valor: 5000,
        data: DateTime(2026, 11, 17, 14, 32),
      ).paraModel();
      final texto = MensagemComprovante.montar(
        detalhe: DetalheParcela(
          parcela: parcela,
          pagamentos: [pagamento],
          parcelasDaVenda: [parcela],
          venda: venda,
        ),
        pagamento: pagamento,
      );
      expect(
        texto,
        'Comprovante de pagamento • Carla Menezes\n'
        'R\$ 50,00 via Pix em 17/11/2026\n'
        'Parcela 1 de 1 • Parcial\n'
        'Saldo restante da venda: R\$ 70,00',
      );
    });
  });
}
