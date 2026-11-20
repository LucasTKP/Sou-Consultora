// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/dto/cliente_dto.dart';
import 'package:sou_consultora/core/dto/endereco_dto.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/filtro_clientes.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/ui/modules/clientes/dados/clientes_dados_screen.dart';
import 'package:sou_consultora/ui/modules/clientes/detalhes/clientes_detalhes_screen.dart';
import 'package:sou_consultora/ui/modules/clientes/formulario/clientes_formulario_cubit.dart';
import 'package:sou_consultora/ui/modules/clientes/formulario/clientes_formulario_screen.dart';
import 'package:sou_consultora/ui/modules/clientes/lista/clientes_lista_cubit.dart';
import 'package:sou_consultora/ui/modules/clientes/lista/clientes_lista_screen.dart';
import 'package:sou_consultora/ui/modules/clientes/lista/clientes_lista_state.dart';

import '../../auxiliares/falsos_clientes.dart';
import '../../auxiliares/montar_app.dart';

final _hoje = DateTime(2026, 11, 17, 10);
DateTime _agora() => _hoje;

ClienteDto _clienteDto({
  bool comEndereco = true,
  String? observacoes = 'Gosta de florais',
}) {
  return ClienteDto(
    id: 'c1',
    nome: 'Dona Carla Menezes',
    whatsapp: '11987654321',
    dataNascimento: DateTime(1980, 11, 14),
    observacoes: observacoes,
    createdAt: DateTime(2025),
    endereco: comEndereco
        ? const EnderecoDto(
            id: 'e1',
            cep: '04567000',
            rua: 'Rua das Acácias',
            numero: '450',
            complemento: 'Apto 82',
            bairro: 'Jd. Paulista',
            uf: 'SP',
          )
        : null,
  );
}

/// Abre [tela] numa rota com uma rota "anterior" para o pop funcionar.
Future<void> _abrir(
  WidgetTester tester,
  RepositorioClientes repositorio,
  String caminho,
) async {
  usarTelaDeCelular(tester);
  injetor.registerSingleton<RepositorioClientes>(repositorio);
  final roteador = GoRouter(
    initialLocation: '/inicio',
    routes: [
      GoRoute(
        path: '/inicio',
        builder: (_, _) => const Scaffold(body: Text('anterior')),
      ),
      GoRoute(
        path: '/clientes',
        builder: (_, _) => const Scaffold(body: ClientesListaScreen()),
      ),
      GoRoute(
        path: '/clientes/novo',
        builder: (_, _) => const ClientesFormularioScreen(),
      ),
      GoRoute(
        path: '/clientes/:id',
        builder: (_, e) =>
            ClientesDetalhesScreen(idCliente: e.pathParameters['id']!),
      ),
      GoRoute(
        path: '/clientes/:id/dados',
        builder: (_, e) =>
            ClientesDadosScreen(idCliente: e.pathParameters['id']!),
      ),
      GoRoute(
        path: '/clientes/:id/editar',
        builder: (_, e) =>
            ClientesFormularioScreen(idCliente: e.pathParameters['id']),
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

/// Rola a lista da tela até [alvo] ser construído (a ListView só monta o visível).
Future<void> _ver(WidgetTester tester, Finder alvo) async {
  await tester.scrollUntilVisible(
    alvo,
    200,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  group('Lista (cubit)', () {
    test('filtra, busca, ordena e acompanha o repositório', () async {
      final servico = ServicoClientesFalso(
        resumos: [
          resumoDto('c1', 'Patrícia Ribeiro'),
          resumoDto('c2', 'Ana Lima', saldo: 12000, atrasado: 12000),
        ],
      );
      final repositorio = repositorioClientesDeTeste(servico);
      final cubit = ClientesListaCubit(repositorio: repositorio, agora: _agora);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.carregamento, CarregamentoClientes.pronto);
      expect(cubit.state.visiveis.map((c) => c.nome), [
        'Ana Lima',
        'Patrícia Ribeiro',
      ]);

      cubit.alterarBusca('patricia');
      expect(cubit.state.visiveis.single.nome, 'Patrícia Ribeiro');

      cubit
        ..alterarBusca('')
        ..alterarStatus(StatusFiltroCliente.comSaldo);
      expect(cubit.state.visiveis.single.nome, 'Ana Lima');
      expect(cubit.state.contagens[StatusFiltroCliente.comSaldo], 1);

      cubit
        ..alterarStatus(StatusFiltroCliente.todos)
        ..inverterOrdem();
      expect(cubit.state.visiveis.first.nome, 'Patrícia Ribeiro');

      await repositorio.salvar(nome: 'Zuleica', whatsapp: '11911112222');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.todas, hasLength(3));
      await cubit.close();
    });

    test(
      'falha no primeiro carregamento mostra erro; tentar novamente carrega',
      () async {
        final servico = ServicoClientesFalso(resumos: [resumoDto('c1', 'Ana')])
          ..falharRede = true;
        final cubit = ClientesListaCubit(
          repositorio: repositorioClientesDeTeste(servico),
          agora: _agora,
        );
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.carregamento, CarregamentoClientes.erro);

        servico.falharRede = false;
        await cubit.carregar();
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.carregamento, CarregamentoClientes.pronto);
        await cubit.close();
      },
    );
  });

  group('Lista (tela)', () {
    testWidgets('mostra contador, selos e abre o detalhe', (tester) async {
      final servico = ServicoClientesFalso(
        resumos: [
          resumoDto(
            'c1',
            'Dona Carla',
            saldo: 12000,
            atrasado: 12000,
            qtdAtrasadas: 2,
          ),
          resumoDto('c2', 'Beatriz Lima', saldo: 8500, venceHoje: 8500),
          resumoDto('c3', 'Mariana Souza'),
          resumoDto('c4', 'Joana Dias', saldo: 3000, atrasado: 3000),
        ],
      );
      await _abrir(tester, repositorioClientesDeTeste(servico), '/clientes');

      Finder linha(String texto) =>
          find.textContaining(texto, findRichText: true);

      expect(find.text('4 clientes'), findsOneWidget);
      // O status vai em texto na segunda linha, sem selo.
      expect(linha('2 atrasadas · R\$ 120,00'), findsOneWidget);
      expect(linha('1 atrasada · R\$ 30,00'), findsOneWidget);
      expect(linha('Vence hoje · R\$ 85,00'), findsOneWidget);
      expect(linha('Em dia · Cliente desde'), findsOneWidget);
      expect(find.text('Deve R\$ 120,00'), findsNothing);

      await tester.tap(find.text('Dona Carla'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhes do Cliente'), findsOneWidget);
    });

    testWidgets('lista vazia convida a cadastrar', (tester) async {
      await _abrir(
        tester,
        repositorioClientesDeTeste(ServicoClientesFalso()),
        '/clientes',
      );
      expect(find.text('Nenhuma cliente ainda'), findsOneWidget);
      expect(find.text('Cadastrar cliente'), findsOneWidget);
      expect(find.text('Novo cliente'), findsNothing);
    });

    testWidgets('busca sem resultado mantém o campo', (tester) async {
      final servico = ServicoClientesFalso(resumos: [resumoDto('c1', 'Ana')]);
      await _abrir(tester, repositorioClientesDeTeste(servico), '/clientes');

      await tester.enterText(find.byType(TextField).at(1), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma cliente encontrada'), findsOneWidget);
    });

    testWidgets('erro com tentar novamente', (tester) async {
      final servico = ServicoClientesFalso(resumos: [resumoDto('c1', 'Ana')])
        ..falharRede = true;
      await _abrir(tester, repositorioClientesDeTeste(servico), '/clientes');
      expect(find.text('Tentar novamente'), findsOneWidget);

      servico.falharRede = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Ana'), findsOneWidget);
    });
  });

  group('Formulário (cubit)', () {
    test('passo 1 inválido não avança; válido vai ao passo 2', () {
      final cubit =
          ClientesFormularioCubit(
              repositorio: repositorioClientesDeTeste(ServicoClientesFalso()),
              agora: _agora,
            )
            ..alterarNome('Ana')
            ..alterarWhatsapp('1199')
            ..continuar();
      expect(cubit.state.passo, 1);
      expect(cubit.state.erroWhatsapp, 'WhatsApp inválido');

      cubit
        ..alterarWhatsapp('(11) 98765-4321')
        ..alterarNascimento('18/11/2026')
        ..continuar();
      expect(cubit.state.erroNascimento, 'Data inválida');

      cubit
        ..alterarNascimento('10/05/1990')
        ..continuar();
      expect(cubit.state.passo, 2);
    });

    test('endereço só com bairro exige rua e número e não grava', () async {
      final servico = ServicoClientesFalso();
      final cubit =
          ClientesFormularioCubit(
              repositorio: repositorioClientesDeTeste(servico),
              agora: _agora,
            )
            ..alterarNome('Ana')
            ..alterarWhatsapp('11987654321')
            ..continuar()
            ..alterarBairro('Centro');
      await cubit.salvar();

      expect(cubit.state.erroRua, 'Obrigatório');
      expect(cubit.state.erroNumero, 'Obrigatório');
      expect(servico.salvos, isEmpty);
    });

    test(
      'CEP preenche rua, bairro, cidade e UF e pede foco no número',
      () async {
        final cep = ServicoCepFalso();
        final cubit = ClientesFormularioCubit(
          repositorio: repositorioClientesDeTeste(
            ServicoClientesFalso(),
            cep: cep,
          ),
        );

        await cubit.alterarCep('01001-000');

        expect(cep.consultas, ['01001000']);
        expect(cubit.state.endereco.rua, 'Praça da Sé');
        expect(cubit.state.endereco.uf, 'SP');
        expect(cubit.state.focarNumero, 1);
        expect(cubit.state.versaoPreenchimento, 1);
      },
    );

    test('CEP não encontrado avisa e mantém os campos', () async {
      final cep = ServicoCepFalso()..resposta = const Sucesso(null);
      final cubit = ClientesFormularioCubit(
        repositorio: repositorioClientesDeTeste(
          ServicoClientesFalso(),
          cep: cep,
        ),
      )..alterarRua('Minha rua');

      await cubit.alterarCep('99999999');

      expect(cubit.state.aviso?.mensagem, 'CEP não encontrado');
      expect(cubit.state.endereco.rua, 'Minha rua');
    });

    test('salvar sem endereço grava e marca salvo', () async {
      final servico = ServicoClientesFalso();
      final cubit =
          ClientesFormularioCubit(
              repositorio: repositorioClientesDeTeste(servico),
              agora: _agora,
            )
            ..alterarNome('Ana')
            ..alterarWhatsapp('11987654321')
            ..continuar();
      await cubit.salvar();

      expect(cubit.state.salvo, isTrue);
      expect(servico.salvos.single['endereco'], isNull);
      expect(servico.salvos.single['whatsapp'], '11987654321');
    });

    test(
      'edição carrega os dados; apagar o endereço envia sem endereço',
      () async {
        final servico = ServicoClientesFalso(clientes: {'c1': _clienteDto()});
        final cubit = ClientesFormularioCubit(
          idCliente: 'c1',
          repositorio: repositorioClientesDeTeste(servico),
          agora: _agora,
        );
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.nome, 'Dona Carla Menezes');
        expect(cubit.state.whatsapp, '(11) 98765-4321');
        expect(cubit.state.nascimento, '14/11/1980');

        cubit
          ..continuar()
          ..alterarCep('')
          ..alterarRua('')
          ..alterarNumero('')
          ..alterarComplemento('')
          ..alterarBairro('')
          ..alterarUf('');
        await cubit.salvar();

        expect(servico.salvos.single['id'], 'c1');
        expect(servico.salvos.single['endereco'], isNull);
      },
    );

    test('falha ao salvar avisa e mantém os dados', () async {
      final servico = ServicoClientesFalso()..falharSalvar = true;
      final cubit =
          ClientesFormularioCubit(
              repositorio: repositorioClientesDeTeste(servico),
              agora: _agora,
            )
            ..alterarNome('Ana')
            ..alterarWhatsapp('11987654321')
            ..continuar();
      await cubit.salvar();

      expect(cubit.state.salvo, isFalse);
      expect(cubit.state.aviso, isNotNull);
      expect(cubit.state.nome, 'Ana');
      expect(cubit.state.passo, 2);
    });
  });

  group('Formulário (tela)', () {
    testWidgets('novo: título, passo 1 de 2 e seta do passo 2 volta ao 1', (
      tester,
    ) async {
      await _abrir(
        tester,
        repositorioClientesDeTeste(ServicoClientesFalso()),
        '/clientes/novo',
      );

      expect(find.text('Novo Cliente'), findsOneWidget);
      expect(find.text('PASSO 1 DE 2'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Ana');
      await tester.enterText(find.byType(TextField).at(1), '11987654321');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('PASSO 2 DE 2'), findsOneWidget);
      expect(find.text('Voltar'), findsNothing); // a seta do cabeçalho volta
      expect(find.text('Salvar Cliente'), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('PASSO 1 DE 2'), findsOneWidget);
      expect(
        find.text('Ana'),
        findsOneWidget,
        reason: 'mantém o que foi digitado',
      );
    });

    testWidgets('editar: título e campos preenchidos', (tester) async {
      final servico = ServicoClientesFalso(clientes: {'c1': _clienteDto()});
      await _abrir(
        tester,
        repositorioClientesDeTeste(servico),
        '/clientes/c1/editar',
      );

      expect(find.text('Editar Cliente'), findsOneWidget);
      expect(find.text('Dona Carla Menezes'), findsOneWidget);
      expect(find.text('(11) 98765-4321'), findsOneWidget);
    });
  });

  group('Detalhes', () {
    testWidgets('com saldo mostra o selo; compras com pedidos e total', (
      tester,
    ) async {
      final servico = ServicoClientesFalso(
        resumos: [
          resumoDto(
            'c1',
            'Dona Carla Menezes',
            saldo: 12000,
            atrasado: 12000,
            compras: 4,
            total: 72400,
          ),
        ],
      );
      await _abrir(tester, repositorioClientesDeTeste(servico), '/clientes/c1');

      expect(find.text('Deve R\$ 120,00'), findsOneWidget);
      expect(find.text('4 pedidos • R\$ 724,00 total gasto'), findsOneWidget);
      expect(find.text('Nova Venda'), findsOneWidget);
    });

    testWidgets('sem compras: "Nenhum pedido ainda" e sem selo', (
      tester,
    ) async {
      final servico = ServicoClientesFalso(
        resumos: [resumoDto('c1', 'Mariana Souza')],
      );
      await _abrir(tester, repositorioClientesDeTeste(servico), '/clientes/c1');

      expect(find.text('Nenhum pedido ainda'), findsOneWidget);
      expect(find.textContaining('Deve'), findsNothing);
    });
  });

  group('Dados cadastrais', () {
    testWidgets('mostra dados e endereço; WhatsApp que não abre avisa', (
      tester,
    ) async {
      final whatsapp = ServicoWhatsappFalso()..abre = false;
      final servico = ServicoClientesFalso(clientes: {'c1': _clienteDto()});
      await _abrir(
        tester,
        repositorioClientesDeTeste(servico, whatsapp: whatsapp),
        '/clientes/c1/dados',
      );

      expect(find.text('(11) 98765-4321'), findsOneWidget);
      expect(find.text('14 de novembro'), findsOneWidget);
      await _ver(tester, find.text('Rua das Acácias, 450 - Apto 82'));
      expect(find.text('Rua das Acácias, 450 - Apto 82'), findsOneWidget);
      expect(find.text('04567-000'), findsOneWidget);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir WhatsApp'));
      await tester.pumpAndSettle();
      expect(whatsapp.aberturas, ['11987654321']);
      expect(find.text('Não foi possível abrir o WhatsApp'), findsOneWidget);
    });

    testWidgets('sem endereço e sem observações', (tester) async {
      final servico = ServicoClientesFalso(
        clientes: {'c1': _clienteDto(comEndereco: false, observacoes: null)},
      );
      await _abrir(
        tester,
        repositorioClientesDeTeste(servico),
        '/clientes/c1/dados',
      );

      await _ver(tester, find.text('Endereço não cadastrado'));
      expect(find.text('Endereço não cadastrado'), findsOneWidget);
      expect(find.text('Preferências & Observações'), findsNothing);
    });

    testWidgets('editar e salvar volta e recarrega os dados', (tester) async {
      final servico = ServicoClientesFalso(clientes: {'c1': _clienteDto()});
      await _abrir(
        tester,
        repositorioClientesDeTeste(servico),
        '/clientes/c1/dados',
      );

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Carla Nova');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar Cliente'));
      await tester.pumpAndSettle();

      expect(find.text('Dados Cadastrais'), findsOneWidget);
      expect(find.text('Carla Nova'), findsWidgets);
    });
  });
}
