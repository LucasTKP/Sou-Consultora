// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/model/filtro_fornecedores.dart';
import 'package:sou_consultora/core/model/fornecedor.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/ui/modules/fornecedores/detalhes/fornecedores_detalhes_screen.dart';
import 'package:sou_consultora/ui/modules/fornecedores/formulario/fornecedores_formulario_cubit.dart';
import 'package:sou_consultora/ui/modules/fornecedores/formulario/fornecedores_formulario_screen.dart';
import 'package:sou_consultora/ui/modules/fornecedores/lista/fornecedores_lista_cubit.dart';
import 'package:sou_consultora/ui/modules/fornecedores/lista/fornecedores_lista_screen.dart';
import 'package:sou_consultora/ui/modules/fornecedores/lista/fornecedores_lista_state.dart';
import 'package:sou_consultora/ui/widgets/formularios/interruptor_app.dart';

import '../../auxiliares/falsos_clientes.dart';
import '../../auxiliares/falsos_fornecedores.dart';
import '../../auxiliares/montar_app.dart';

/// Abre [caminho] com uma rota "anterior" para o pop funcionar.
Future<void> _abrir(
  WidgetTester tester,
  RepositorioFornecedores repositorio,
  String caminho,
) async {
  usarTelaDeCelular(tester);
  injetor.registerSingleton<RepositorioFornecedores>(repositorio);
  final roteador = GoRouter(
    initialLocation: '/inicio',
    routes: [
      GoRoute(
        path: '/inicio',
        builder: (_, _) => const Scaffold(body: Text('anterior')),
      ),
      GoRoute(
        path: '/a-pagar/fornecedor/:id',
        builder: (_, e) =>
            Scaffold(body: Text('boletos de ${e.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/fornecedores',
        builder: (_, _) => const Scaffold(body: FornecedoresListaScreen()),
      ),
      GoRoute(
        path: '/fornecedores/novo',
        builder: (_, _) => const FornecedoresFormularioScreen(),
      ),
      GoRoute(
        path: '/fornecedores/:id',
        builder: (_, e) =>
            FornecedoresDetalhesScreen(idFornecedor: e.pathParameters['id']!),
      ),
      GoRoute(
        path: '/fornecedores/:id/editar',
        builder: (_, e) =>
            FornecedoresFormularioScreen(idFornecedor: e.pathParameters['id']),
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
    test('filtra, busca, ordena e acompanha o repositório', () async {
      final servico = ServicoFornecedoresFalso(
        resumos: [
          fornecedorDto('f1', 'O Boticário', qtdVenceHoje: 1, qtdEmAberto: 1),
          fornecedorDto('f2', 'Natura'),
          fornecedorDto('f3', 'Mary Kay', ativo: false),
        ],
      );
      final repositorio = repositorioFornecedoresDeTeste(servico);
      final cubit = FornecedoresListaCubit(repositorio: repositorio);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.carregamento, CarregamentoFornecedores.pronto);
      expect(cubit.state.visiveis.map((f) => f.nome), [
        'Mary Kay',
        'Natura',
        'O Boticário',
      ]);

      cubit.alterarBusca('boticario');
      expect(cubit.state.visiveis.single.nome, 'O Boticário');

      cubit
        ..alterarBusca('')
        ..alterarStatus(StatusFiltroFornecedor.emEspera);
      expect(cubit.state.visiveis.single.nome, 'Mary Kay');
      expect(cubit.state.contagens[StatusFiltroFornecedor.venceHoje], 1);

      cubit
        ..alterarStatus(StatusFiltroFornecedor.todos)
        ..inverterOrdem();
      expect(cubit.state.visiveis.first.nome, 'O Boticário');

      await repositorio.salvar(Fornecedor(nome: 'Hinode'));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.todos, hasLength(4));
      await cubit.close();
    });
  });

  group('Lista (tela)', () {
    testWidgets('mostra contador, selos, boletos e abre o detalhe', (
      tester,
    ) async {
      final servico = ServicoFornecedoresFalso(
        resumos: [
          fornecedorDto('f1', 'Natura', qtdEmAberto: 2),
          fornecedorDto('f2', 'Avon', qtdEmAberto: 1, qtdVenceHoje: 1),
          fornecedorDto('f3', 'Mary Kay', ativo: false),
        ],
      );
      await _abrir(
        tester,
        repositorioFornecedoresDeTeste(servico),
        '/fornecedores',
      );

      expect(find.text('3 fornecedores'), findsOneWidget);
      expect(find.text('Ativo'), findsOneWidget);
      expect(find.text('Vence hoje'), findsOneWidget);
      expect(find.text('Em espera'), findsOneWidget);
      expect(find.text('2 boletos em aberto'), findsOneWidget);
      expect(find.text('Nenhum boleto em aberto'), findsOneWidget);
      expect(find.text('Fornecedor'), findsOneWidget);

      await tester.tap(find.text('Natura'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhes do Fornecedor'), findsOneWidget);
    });

    testWidgets('lista vazia convida a cadastrar', (tester) async {
      await _abrir(
        tester,
        repositorioFornecedoresDeTeste(ServicoFornecedoresFalso()),
        '/fornecedores',
      );
      expect(find.text('Nenhum fornecedor ainda'), findsOneWidget);
      expect(find.text('Cadastrar fornecedor'), findsOneWidget);
      expect(find.text('Fornecedor'), findsNothing);
    });

    testWidgets('busca sem resultado mantém o campo', (tester) async {
      final servico = ServicoFornecedoresFalso(
        resumos: [fornecedorDto('f1', 'Natura')],
      );
      await _abrir(
        tester,
        repositorioFornecedoresDeTeste(servico),
        '/fornecedores',
      );

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Nenhum fornecedor encontrado'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('erro com tentar novamente', (tester) async {
      final servico = ServicoFornecedoresFalso(
        resumos: [fornecedorDto('f1', 'Natura')],
      )..falharRede = true;
      await _abrir(
        tester,
        repositorioFornecedoresDeTeste(servico),
        '/fornecedores',
      );
      expect(find.text('Tentar novamente'), findsOneWidget);

      servico.falharRede = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Natura'), findsOneWidget);
    });
  });

  group('Formulário (cubit)', () {
    test('nome vazio e telefone incompleto não gravam', () async {
      final servico = ServicoFornecedoresFalso();
      final cubit = FornecedoresFormularioCubit(
        repositorio: repositorioFornecedoresDeTeste(servico),
      )..alterarTelefone('(11) 9876');

      await cubit.salvar();

      expect(cubit.state.erroNome, 'Informe o nome do fornecedor');
      expect(cubit.state.erroTelefone, 'Telefone incompleto');
      expect(servico.salvos, isEmpty);
      await cubit.close();
    });

    test('novo grava ativo, com telefone só em dígitos', () async {
      final servico = ServicoFornecedoresFalso();
      final cubit =
          FornecedoresFormularioCubit(
              repositorio: repositorioFornecedoresDeTeste(servico),
            )
            ..alterarNome(' Natura ')
            ..alterarTelefone('(11) 98765-4321')
            ..alterarEmEspera(true);

      await cubit.salvar();

      final salvo = servico.salvos.single;
      expect(salvo.id, isNull);
      expect(salvo.fornecedor.nome, 'Natura');
      expect(salvo.fornecedor.telefone, '11987654321');
      expect(salvo.fornecedor.ativo, isTrue, reason: 'o novo nasce ativo');
      expect(cubit.state.salvo, isTrue);
      await cubit.close();
    });

    test('nome repetido mostra o aviso e mantém os campos', () async {
      final servico = ServicoFornecedoresFalso()
        ..falhaAoSalvar = const FalhaValidacao(Fornecedor.mensagemDuplicado);
      final cubit = FornecedoresFormularioCubit(
        repositorio: repositorioFornecedoresDeTeste(servico),
      )..alterarNome('natura');

      await cubit.salvar();

      expect(cubit.state.aviso?.mensagem, Fornecedor.mensagemDuplicado);
      expect(cubit.state.nome, 'natura');
      expect(cubit.state.salvo, isFalse);
      await cubit.close();
    });

    test('editar carrega os dados e envia o status em espera', () async {
      final servico = ServicoFornecedoresFalso(
        resumos: [fornecedorDto('f1', 'Mary Kay', telefone: '11987654321')],
      );
      final cubit = FornecedoresFormularioCubit(
        idFornecedor: 'f1',
        repositorio: repositorioFornecedoresDeTeste(servico),
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.telefone, '(11) 98765-4321');

      cubit.alterarEmEspera(true);
      await cubit.salvar();

      expect(servico.salvos.single.id, 'f1');
      expect(servico.salvos.single.fornecedor.ativo, isFalse);
      await cubit.close();
    });
  });

  group('Formulário (tela)', () {
    testWidgets('novo: título, sem interruptor; cancelar não grava', (
      tester,
    ) async {
      final servico = ServicoFornecedoresFalso();
      await _abrir(
        tester,
        repositorioFornecedoresDeTeste(servico),
        '/fornecedores/novo',
      );

      expect(find.text('Novo Fornecedor'), findsOneWidget);
      expect(find.byType(InterruptorApp), findsNothing);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('anterior'), findsOneWidget);
      expect(servico.salvos, isEmpty);
    });

    testWidgets('editar: título, campos preenchidos e interruptor', (
      tester,
    ) async {
      final servico = ServicoFornecedoresFalso(
        resumos: [fornecedorDto('f1', 'Natura', ramo: 'Cosméticos')],
      );
      await _abrir(
        tester,
        repositorioFornecedoresDeTeste(servico),
        '/fornecedores/f1/editar',
      );

      expect(find.text('Editar Fornecedor'), findsOneWidget);
      expect(find.text('Natura'), findsOneWidget);
      expect(find.text('Cosméticos'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(InterruptorApp),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Em espera'), findsOneWidget);
    });
  });

  group('Detalhes', () {
    testWidgets('mostra identidade, boletos e contato; sem excluir', (
      tester,
    ) async {
      final servico = ServicoFornecedoresFalso(
        resumos: [
          fornecedorDto(
            'f1',
            'Natura',
            ramo: 'Cosméticos e Perfumaria',
            contato: 'Mariana Silva',
            telefone: '11987654321',
            observacoes: 'Ciclo às terças',
            qtdEmAberto: 2,
            valorEmAberto: 77000,
            qtdPagos: 4,
            valorPagos: 101000,
            criadoEm: DateTime(2023, 3, 10),
          ),
        ],
      );
      final whatsapp = ServicoWhatsappFalso()..abre = false;
      await _abrir(
        tester,
        repositorioFornecedoresDeTeste(servico, whatsapp: whatsapp),
        '/fornecedores/f1',
      );

      expect(find.text('Cosméticos e Perfumaria'), findsOneWidget);
      expect(find.text('Ativo'), findsOneWidget);
      expect(find.text('Parceiro desde mar/2023'), findsOneWidget);
      expect(find.text('R\$ 770,00'), findsOneWidget);
      expect(find.text('2 boletos'), findsOneWidget);
      expect(find.text('0 boletos'), findsOneWidget);
      expect(find.text('(11) 98765-4321'), findsOneWidget);
      expect(find.textContaining('Excluir'), findsNothing);

      await tester.ensureVisible(find.text('WhatsApp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();
      expect(whatsapp.aberturas, ['11987654321']);
      expect(find.text('Não foi possível abrir o WhatsApp'), findsOneWidget);
    });

    testWidgets('sem telefone esconde o WhatsApp; sem boletos tudo zerado', (
      tester,
    ) async {
      final servico = ServicoFornecedoresFalso(
        resumos: [fornecedorDto('f1', 'Hinode')],
      );
      await _abrir(
        tester,
        repositorioFornecedoresDeTeste(servico),
        '/fornecedores/f1',
      );

      expect(find.text('WhatsApp'), findsNothing);
      expect(find.text('R\$ 0,00'), findsNWidgets(3));
      expect(find.text('0 boletos'), findsNWidgets(3));
    });

    testWidgets('editar e salvar volta e recarrega os detalhes', (
      tester,
    ) async {
      final servico = ServicoFornecedoresFalso(
        resumos: [fornecedorDto('f1', 'Mary Kay')],
      );
      await _abrir(
        tester,
        repositorioFornecedoresDeTeste(servico),
        '/fornecedores/f1',
      );

      await tester.tap(find.text('Editar Fornecedor'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(InterruptorApp),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Em espera'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Detalhes do Fornecedor'), findsOneWidget);
      expect(find.text('Em espera'), findsOneWidget);
    });

    testWidgets(
      'Ver em A pagar abre os boletos da marca e recarrega na volta',
      (tester) async {
        final servico = ServicoFornecedoresFalso(
          resumos: [fornecedorDto('f1', 'Natura')],
        );
        await _abrir(
          tester,
          repositorioFornecedoresDeTeste(servico),
          '/fornecedores/f1',
        );

        await tester.tap(find.text('Ver em A pagar'));
        await tester.pumpAndSettle();
        expect(find.text('boletos de f1'), findsOneWidget);

        // Lá ela pagou um boleto: o resumo da marca precisa mudar na volta.
        servico.resumos = [
          fornecedorDto('f1', 'Natura', qtdPagos: 1, valorPagos: 68000),
        ];
        servico.chamadas.clear();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Detalhes do Fornecedor'), findsOneWidget);
        expect(servico.chamadas, contains('resumo f1'));
        expect(find.text('R\$ 680,00'), findsOneWidget);
      },
    );
  });
}
