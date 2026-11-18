// ignore_for_file: deprecated_member_use
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/dto/boleto_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/model/arquivo_comprovante.dart';
import 'package:sou_consultora/core/model/filtro_boletos.dart';
import 'package:sou_consultora/core/model/forma_pagamento_boleto.dart';
import 'package:sou_consultora/core/repository/repositorio_boletos.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/ui/modules/a_pagar/detalhes/a_pagar_detalhes_cubit.dart';
import 'package:sou_consultora/ui/modules/a_pagar/detalhes/a_pagar_detalhes_screen.dart';
import 'package:sou_consultora/ui/modules/a_pagar/formulario/a_pagar_formulario_cubit.dart';
import 'package:sou_consultora/ui/modules/a_pagar/formulario/a_pagar_formulario_screen.dart';
import 'package:sou_consultora/ui/modules/a_pagar/lista/a_pagar_lista_cubit.dart';
import 'package:sou_consultora/ui/modules/a_pagar/lista/a_pagar_lista_screen.dart';
import 'package:sou_consultora/ui/modules/a_pagar/lista/widgets/cartao_boleto.dart';

import 'package:sou_consultora/ui/widgets/formularios/campo_data_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_selecao_app.dart';

import '../../auxiliares/falsos_boletos.dart';
import '../../auxiliares/falsos_consultora.dart';
import '../../auxiliares/falsos_fornecedores.dart';
import '../../auxiliares/montar_app.dart';

class _Ambiente {
  _Ambiente({List<BoletoDto>? boletos})
    : servicoFornecedores = ServicoFornecedoresFalso(
        resumos: [
          fornecedorDto('f1', 'Natura'),
          fornecedorDto('f2', 'Eudora'),
          fornecedorDto('f3', 'Marca em espera', ativo: false),
        ],
      ),
      links = ServicoAbrirLinkFalso(),
      escolher = EscolherComprovanteFalso() {
    servico = ServicoBoletosFalso(
      boletos: boletos ?? [],
      nomesFornecedores: {'f1': 'Natura', 'f2': 'Eudora'},
    );
    fornecedores = repositorioFornecedoresDeTeste(servicoFornecedores);
    repositorio = repositorioBoletosDeTeste(
      servico,
      fornecedores: fornecedores,
      abrirLink: links,
      escolher: escolher,
    );
  }

  final ServicoFornecedoresFalso servicoFornecedores;
  final ServicoAbrirLinkFalso links;
  final EscolherComprovanteFalso escolher;
  late final ServicoBoletosFalso servico;
  late final RepositorioFornecedores fornecedores;
  late final RepositorioBoletos repositorio;

  /// Abre o formulário real em Novo boleto (a lista usa um marcador).
  bool formularioDeVerdade = false;

  /// Abre os detalhes reais (a lista usa um marcador).
  bool detalhesDeVerdade = false;

  void registrar() {
    injetor
      ..registerSingleton<RepositorioBoletos>(repositorio)
      ..registerSingleton<RepositorioFornecedores>(fornecedores)
      ..registerSingleton<RepositorioConsultora>(
        repositorioDeTeste(ServicoConsultoraFalso(registro: dtoDeTeste())),
      );
  }
}

Future<void> _abrir(
  WidgetTester tester,
  _Ambiente ambiente,
  String caminho,
) async {
  usarTelaDeCelular(tester);
  ambiente.registrar();
  final roteador = GoRouter(
    initialLocation: '/inicio',
    routes: [
      GoRoute(
        path: '/inicio',
        builder: (_, _) => const Scaffold(body: Text('anterior')),
      ),
      GoRoute(
        path: '/a-pagar',
        builder: (_, _) => const Scaffold(body: APagarListaScreen()),
      ),
      GoRoute(
        path: '/a-pagar/novo',
        builder: (_, e) => ambiente.formularioDeVerdade
            ? APagarFormularioScreen(
                fornecedorInicialId: e.uri.queryParameters['fornecedor'],
              )
            : Scaffold(
                body: Text('novo ${e.uri.queryParameters['fornecedor']}'),
              ),
      ),
      GoRoute(
        path: '/a-pagar/:id/editar',
        builder: (_, e) =>
            APagarFormularioScreen(idBoleto: e.pathParameters['id']),
      ),
      GoRoute(
        path: '/a-pagar/fornecedor/:id',
        builder: (_, e) =>
            APagarListaScreen(fornecedorId: e.pathParameters['id']),
      ),
      GoRoute(
        path: '/a-pagar/:id',
        builder: (_, e) => ambiente.detalhesDeVerdade
            ? APagarDetalhesScreen(idBoleto: e.pathParameters['id']!)
            : Scaffold(body: Text('boleto ${e.pathParameters['id']}')),
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

  group('Lista (cubit e textos do card)', () {
    final hoje = DateTime(2026, 11, 12, 9);

    test('textos do card em cada situação', () {
      String linha(DateTime vencimento, {DateTime? pagoEm, String? forma}) {
        final t = CartaoBoleto.textosDe(
          boletoDto(
            'b',
            vencimento: vencimento,
            pagoEm: pagoEm,
            forma: forma,
          ).paraModel(),
          hoje: hoje,
        );
        return '${t.rotuloData} | ${t.data} | ${t.complemento} | ${t.rotuloValor}';
      }

      expect(
        linha(DateTime(2026, 11, 12)),
        'Vencimento | Hoje (12/11/2026) | null | Valor a pagar',
      );
      expect(
        linha(DateTime(2026, 11, 18)),
        'Vencimento | 18/11/2026 | (em 6 dias) | Valor a pagar',
      );
      expect(
        linha(DateTime(2026, 11, 13)),
        'Vencimento | 13/11/2026 | (amanhã) | Valor a pagar',
      );
      expect(
        linha(DateTime(2026, 11, 5)),
        'Venceu em | 05/11/2026 | (7 dias) | Valor original',
      );
      expect(
        linha(
          DateTime(2026, 11, 5),
          pagoEm: DateTime(2026, 11, 1),
          forma: 'pix',
        ),
        'Liquidado em | 01/11/2026 | via Pix | Valor liquidado',
      );
    });

    test('pelo fornecedor: todos os meses e só a marca', () async {
      final ambiente = _Ambiente(
        boletos: [
          boletoDto('n1', vencimento: DateTime(2026, 9, 1)),
          boletoDto('n2', vencimento: DateTime(2026, 11, 20)),
          boletoDto(
            'e1',
            fornecedorId: 'f2',
            fornecedor: 'Eudora',
            vencimento: DateTime(2026, 11, 5),
          ),
        ],
      );
      final cubit = APagarListaCubit(
        fornecedorId: 'f1',
        repositorio: ambiente.repositorio,
        agora: () => hoje,
      );
      addTearDown(cubit.close);
      await pumpEventQueue();

      expect(cubit.state.mes, isNull);
      expect(cubit.state.nomeFornecedor, 'Natura');
      expect(cubit.state.visiveis.map((b) => b.id), ['n1', 'n2']);
      expect(cubit.state.contagens[StatusFiltroBoleto.atrasado], 1);
    });

    test('erro de rede mostra a mensagem', () async {
      final ambiente = _Ambiente()..servico.falharRede = true;
      final cubit = APagarListaCubit(
        repositorio: ambiente.repositorio,
        agora: () => hoje,
      );
      addTearDown(cubit.close);
      await pumpEventQueue();
      expect(cubit.state.mensagemErro, contains('Sem conexão'));
    });
  });

  group('Lista (tela)', () {
    testWidgets('mês atual, busca pela observação e abre o boleto', (
      tester,
    ) async {
      final hoje = DateTime.now();
      final ambiente = _Ambiente(
        boletos: [
          boletoDto(
            'b1',
            vencimento: hoje,
            valor: 68000,
            observacoes: 'Ciclo 15',
          ),
          boletoDto(
            'b2',
            fornecedorId: 'f2',
            fornecedor: 'Eudora',
            vencimento: hoje,
            valor: 31000,
            pagoEm: hoje,
            forma: 'pix',
          ),
          // Daqui a 2 meses: fora do filtro padrão (mês atual).
          boletoDto(
            'b3',
            fornecedor: 'Fora do Mês',
            vencimento: DateTime(hoje.year, hoje.month + 2, 10),
          ),
        ],
      );
      await _abrir(tester, ambiente, '/a-pagar');

      expect(find.text('A pagar'), findsOneWidget);
      expect(find.text('2 boletos'), findsOneWidget);
      expect(find.text('Fora do Mês'), findsNothing);
      expect(find.text('Vence hoje'), findsOneWidget);
      expect(find.text('R\$ 680,00'), findsOneWidget);
      expect(find.text('Pago'), findsOneWidget);
      expect(find.text('Valor liquidado'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).first, 'ciclo');
      await tester.pumpAndSettle();
      expect(find.text('1 boleto'), findsOneWidget);
      expect(find.text('Eudora'), findsNothing);

      await tester.tap(find.text('Natura'));
      await tester.pumpAndSettle();
      expect(find.text('boleto b1'), findsOneWidget);
    });

    testWidgets('+ e Novo boleto abrem o lançamento', (tester) async {
      await _abrir(
        tester,
        _Ambiente(boletos: [boletoDto('b1', vencimento: DateTime.now())]),
        '/a-pagar',
      );
      await tester.tap(find.byTooltip('Novo boleto'));
      await tester.pumpAndSettle();
      expect(find.text('novo null'), findsOneWidget);
    });

    testWidgets('pelo fornecedor: seta de voltar, nome da marca e só ela', (
      tester,
    ) async {
      final ambiente = _Ambiente(
        boletos: [
          boletoDto('n1', vencimento: DateTime.now()),
          boletoDto(
            'e1',
            fornecedorId: 'f2',
            fornecedor: 'Eudora',
            // Outro mês: aparece, porque pelo fornecedor são todos os meses.
            vencimento: DateTime.now().subtract(const Duration(days: 60)),
          ),
        ],
      );
      await _abrir(tester, ambiente, '/a-pagar/fornecedor/f2');

      expect(find.text('EUDORA'), findsOneWidget);
      expect(find.text('1 boleto'), findsOneWidget);
      expect(find.text('Natura'), findsNothing);
      expect(find.text('Atrasado'), findsOneWidget);

      await tester.tap(find.text('Novo boleto'));
      await tester.pumpAndSettle();
      expect(find.text('novo f2'), findsOneWidget);
    });

    testWidgets('sem boletos convida a lançar', (tester) async {
      await _abrir(tester, _Ambiente(), '/a-pagar');
      expect(find.text('Nenhum boleto ainda'), findsOneWidget);
      expect(find.text('Lançar boleto'), findsOneWidget);
    });
  });

  group('Novo / editar boleto', () {
    test('passo 1 exige marca, valor e vencimento; só marcas ativas', () async {
      final ambiente = _Ambiente();
      final cubit = APagarFormularioCubit(
        boletos: ambiente.repositorio,
        fornecedores: ambiente.fornecedores,
      );
      addTearDown(cubit.close);
      await pumpEventQueue();

      expect(cubit.state.marcasDisponiveis.map((m) => m.nome), [
        'Natura',
        'Eudora',
      ]);
      cubit.continuar();
      expect(cubit.state.passo, 1);
      expect(cubit.state.erroMarca, 'Escolha a marca do boleto');
      expect(cubit.state.erroValor, 'Informe o valor do boleto');
      expect(cubit.state.erroVencimento, 'Informe a data de vencimento');

      cubit
        ..alterarMarca(cubit.state.marcas.first)
        ..alterarValor(68000)
        ..alterarVencimento(DateTime(2026, 11, 25))
        ..continuar();
      expect(cubit.state.passo, 2);
      expect(cubit.state.erroMarca, isNull);
    });

    test('marca inicial só se estiver ativa', () async {
      Future<String?> inicial(String id) async {
        final ambiente = _Ambiente();
        final cubit = APagarFormularioCubit(
          fornecedorInicialId: id,
          boletos: ambiente.repositorio,
          fornecedores: ambiente.fornecedores,
        );
        addTearDown(cubit.close);
        await pumpEventQueue();
        return cubit.state.fornecedorId;
      }

      expect(await inicial('f2'), 'f2');
      expect(await inicial('f3'), isNull);
    });

    test('edição: preenche, mostra a marca em espera e grava', () async {
      final ambiente = _Ambiente(
        boletos: [
          boletoDto(
            'b1',
            fornecedorId: 'f3',
            fornecedor: 'Marca em espera',
            fornecedorAtivo: false,
            valor: 31000,
            vencimento: DateTime(2026, 11, 5),
            forma: 'boleto',
            observacoes: 'Ciclo 15',
          ),
        ],
      );
      final cubit = APagarFormularioCubit(
        idBoleto: 'b1',
        boletos: ambiente.repositorio,
        fornecedores: ambiente.fornecedores,
      );
      addTearDown(cubit.close);
      await pumpEventQueue();

      expect(cubit.state.valor, 31000);
      expect(cubit.state.observacoes, 'Ciclo 15');
      expect(
        cubit.state.marcasDisponiveis.map((m) => m.nome),
        contains('Marca em espera'),
      );

      cubit
        ..alterarValor(29000)
        ..alterarForma(null)
        ..alterarObservacoes('   ');
      await cubit.salvar();
      final salvo = ambiente.servico.salvos.single;
      expect(salvo.id, 'b1');
      expect(salvo.pedido.valor, 29000);
      expect(salvo.pedido.forma, isNull);
      expect(salvo.pedido.observacoes, isNull);
      expect(cubit.state.salvo, isTrue);
    });

    testWidgets('tela: avisa os campos, confere no passo 2 e salva', (
      tester,
    ) async {
      final ambiente = _Ambiente()..formularioDeVerdade = true;
      await _abrir(tester, ambiente, '/a-pagar/novo?fornecedor=f1');

      expect(find.text('Novo Boleto'), findsOneWidget);
      expect(find.text('Passo 1 de 2: Dados do Boleto'), findsOneWidget);
      // A marca já vem da lista da Natura.
      expect(find.text('Natura'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Informe o valor do boleto'), findsOneWidget);
      expect(find.text('Informe a data de vencimento'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(CampoMoedaApp),
          matching: find.byType(EditableText),
        ),
        '68000',
      );
      await tester.tap(find.byType(CampoDataApp));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Passo 2 de 2: Pagamento e Lembretes'), findsOneWidget);
      expect(find.text('Confirmado'), findsOneWidget);
      expect(find.text('R\$ 680,00'), findsOneWidget);

      await tester.tap(find.byType(CampoSelecaoApp<FormaPagamentoBoleto?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pix').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).last, 'Ciclo 15');
      await tester.tap(find.text('Salvar Boleto'));
      await tester.pumpAndSettle();

      expect(find.text('anterior'), findsOneWidget);
      final pedido = ambiente.servico.salvos.single.pedido;
      expect(pedido.fornecedorId, 'f1');
      expect(pedido.valor, 68000);
      expect(pedido.forma?.rotulo, 'Pix');
      expect(pedido.observacoes, 'Ciclo 15');
    });

    testWidgets('tela: voltar do passo 2 mantém o que foi digitado', (
      tester,
    ) async {
      final ambiente = _Ambiente(
        boletos: [
          boletoDto(
            'b1',
            valor: 68000,
            vencimento: DateTime(2026, 11, 25),
            observacoes: 'Ciclo 15',
          ),
        ],
      )..formularioDeVerdade = true;
      await _abrir(tester, ambiente, '/a-pagar/b1/editar');

      expect(find.text('Editar Boleto'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Ciclo 15'), findsOneWidget);
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Passo 1 de 2: Dados do Boleto'), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byType(CampoMoedaApp),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        '680,00',
      );
    });
  });

  group('Detalhes do boleto', () {
    /// Boleto da Natura de R$ 680,00, vencendo daqui a 7 dias, com observação.
    _Ambiente pendente({String? comprovante, DateTime? pagoEm}) => _Ambiente(
      boletos: [
        boletoDto(
          'b1',
          valor: 68000,
          forma: 'pix',
          observacoes: 'Ciclo 15. Desconto de R\$ 20 se pago até dia 20.',
          comprovante: comprovante,
          pagoEm: pagoEm,
        ),
      ],
    )..detalhesDeVerdade = true;

    APagarDetalhesCubit cubitDe(_Ambiente ambiente, DateTime hoje) {
      final cubit = APagarDetalhesCubit(
        idBoleto: 'b1',
        repositorio: ambiente.repositorio,
        agora: () => hoje,
      );
      addTearDown(cubit.close);
      return cubit;
    }

    test('pagar valida a data e mostra o erro do banco', () async {
      final hoje = DateTime.now();
      final ambiente = pendente();
      final cubit = cubitDe(ambiente, hoje);
      await pumpEventQueue();

      expect(await cubit.pagar(hoje.add(const Duration(days: 1))), isFalse);
      expect(
        cubit.state.erroDataPagamento,
        'A data do pagamento não pode ser no futuro',
      );
      expect(ambiente.servico.chamadas, isNot(contains('pagar b1')));

      ambiente.servico.falhaAoGravar = const FalhaValidacao(
        'A data do pagamento não pode ser no futuro.',
      );
      expect(await cubit.pagar(hoje), isFalse);
      expect(cubit.state.erroPagamento, contains('futuro'));

      ambiente.servico.falhaAoGravar = null;
      final ontem = hoje.subtract(const Duration(days: 1));
      expect(await cubit.pagar(ontem), isTrue);
      expect(cubit.state.boleto!.pago, isTrue);
      expect(
        cubit.state.boleto!.dataPagamento,
        DateTime(ontem.year, ontem.month, ontem.day),
      );
    });

    test('anexar: desistir não envia; escolher envia e avisa', () async {
      final ambiente = pendente();
      final cubit = cubitDe(ambiente, DateTime.now());
      await pumpEventQueue();

      await cubit.anexarComprovante(OrigemComprovante.galeria);
      expect(ambiente.servico.enviados, isEmpty);

      ambiente.escolher.arquivo = ArquivoComprovante(
        bytes: Uint8List.fromList([1, 2]),
        tipo: TipoComprovante.pdf,
      );
      await cubit.anexarComprovante(OrigemComprovante.pdf);
      expect(ambiente.servico.enviados, ['id-ana/boletos/b1/1.pdf']);
      expect(cubit.state.boleto!.comprovanteEmPdf, isTrue);
    });

    testWidgets('pendente: dados e Confirmar pagamento com a data de hoje', (
      tester,
    ) async {
      final ambiente = pendente();
      await _abrir(tester, ambiente, '/a-pagar/b1');

      expect(find.text('Detalhes do Boleto'), findsOneWidget);
      expect(find.text('VALOR A PAGAR'), findsOneWidget);
      expect(find.text('R\$ 680,00'), findsOneWidget);
      expect(find.text('Pendente'), findsOneWidget);
      expect(find.text('Pix'), findsOneWidget);
      expect(find.textContaining('Ciclo 15'), findsOneWidget);
      expect(find.text('Pago em'), findsNothing);

      await tester.tap(find.text('Confirmar Pagamento'));
      await tester.pumpAndSettle();
      expect(
        find.text('O boleto de R\$ 680,00 é quitado inteiro.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Pagamento confirmado.'), findsOneWidget);
      expect(find.text('VALOR PAGO'), findsOneWidget);
      expect(find.text('Pago em'), findsOneWidget);
      expect(find.text('Confirmar Pagamento'), findsNothing);
      // Pagar recarrega também os fornecedores (números da marca).
      expect(ambiente.servicoFornecedores.chamadas, contains('listar'));
    });

    testWidgets('pago: ver comprovante e desfazer o pagamento', (tester) async {
      final ambiente = pendente(
        comprovante: 'id-ana/boletos/b1/antigo.pdf',
        pagoEm: DateTime.now(),
      );
      await _abrir(tester, ambiente, '/a-pagar/b1');

      expect(find.text('Confirmar Pagamento'), findsNothing);
      await tester.tap(find.text('Ver comprovante'));
      await tester.pumpAndSettle();
      expect(ambiente.links.abertos, [
        'https://assinada/id-ana/boletos/b1/antigo.pdf',
      ]);

      await tester.tap(find.text('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desfazer Pagamento'));
      await tester.pumpAndSettle();
      expect(find.text('Desfazer o pagamento?'), findsOneWidget);
      await tester.tap(find.text('Desfazer'));
      await tester.pumpAndSettle();

      expect(find.text('Pagamento desfeito.'), findsOneWidget);
      expect(find.text('Confirmar Pagamento'), findsOneWidget);
      // A forma e o comprovante continuam.
      expect(find.text('Ver comprovante'), findsOneWidget);
    });

    testWidgets('opções: anexar PDF, editar e excluir', (tester) async {
      final ambiente = pendente(comprovante: 'id-ana/boletos/b1/antigo.pdf');
      ambiente.escolher.arquivo = ArquivoComprovante(
        bytes: Uint8List.fromList([1, 2]),
        tipo: TipoComprovante.pdf,
      );
      await _abrir(tester, ambiente, '/a-pagar/b1');

      // Não pago: sem Desfazer.
      await tester.tap(find.text('Mais opções'));
      await tester.pumpAndSettle();
      expect(find.text('Desfazer Pagamento'), findsNothing);
      await tester.tap(find.text('Baixar / Anexar Comprovante'));
      await tester.pumpAndSettle();
      expect(find.text('Anexar outro substitui o atual.'), findsOneWidget);
      await tester.tap(find.text('Escolher PDF'));
      await tester.pumpAndSettle();
      expect(ambiente.escolher.origens, [OrigemComprovante.pdf]);
      expect(find.text('Comprovante anexado.'), findsOneWidget);
      expect(ambiente.servico.removidos, ['id-ana/boletos/b1/antigo.pdf']);
      // O aviso flutua sobre os botões até sumir sozinho.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar Boleto'));
      await tester.pumpAndSettle();
      expect(find.text('Passo 1 de 2: Dados do Boleto'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir Boleto'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('O boleto da Natura de R\$ 680,00'),
        findsOneWidget,
      );
      await tester.tap(find.text('Excluir boleto'));
      await tester.pumpAndSettle();

      expect(find.text('anterior'), findsOneWidget);
      expect(ambiente.servico.boletos, isEmpty);
      expect(ambiente.servico.removidos, contains('id-ana/boletos/b1/1.pdf'));
    });

    testWidgets('boleto inexistente mostra o erro', (tester) async {
      await _abrir(tester, pendente(), '/a-pagar/nao-existe');
      expect(find.text('Boleto não encontrado.'), findsOneWidget);
    });
  });
}
