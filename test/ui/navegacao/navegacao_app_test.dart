// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/dto/resumo_parcela_dto.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/resumo_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/ui/navegacao/casca/widgets/barra_inferior.dart';
import 'package:sou_consultora/ui/navegacao/casca/widgets/item_menu_lateral.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_boletos.dart';
import 'package:sou_consultora/core/repository/repositorio_categorias.dart';
import 'package:sou_consultora/core/repository/repositorio_estoque.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/core/repository/repositorio_inicio.dart';
import 'package:sou_consultora/core/repository/repositorio_recebimentos.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/core/repository/repositorio_servicos.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/ui/navegacao/notificador_acesso.dart';
import 'package:sou_consultora/ui/navegacao/roteador_app.dart';

import '../../auxiliares/falsos_boletos.dart';
import '../../auxiliares/falsos_clientes.dart';
import '../../auxiliares/falsos_inicio.dart';
import '../../auxiliares/falsos_recebimentos.dart';
import '../../auxiliares/falsos_consultora.dart';
import '../../auxiliares/falsos_fornecedores.dart';
import '../../auxiliares/falsos_estoque.dart';
import '../../auxiliares/falsos_produtos.dart';
import '../../auxiliares/falsos_servicos.dart';
import '../../auxiliares/falsos_vendas.dart';
import '../../auxiliares/montar_app.dart';

class _RepositorioFalso implements RepositorioAutenticacao {
  _RepositorioFalso({required this.logado, required this.nomeLogin});

  final String nomeLogin;

  bool logado;
  int saidas = 0;
  final _sessao = StreamController<bool>.broadcast();

  void mudarSessao(bool ativa) {
    logado = ativa;
    _sessao.add(ativa);
  }

  @override
  bool get estaLogado => logado;

  @override
  Stream<bool> get sessaoAtiva => _sessao.stream;

  @override
  ResumoConsultora resumoDaConsultora() =>
      ResumoConsultora.de(nome: nomeLogin, email: 'ana@email.com');

  @override
  Future<Resultado<void>> sair() async {
    saidas++;
    mudarSessao(false);
    return const Sucesso(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late _RepositorioFalso _repositorio;
late ServicoConsultoraFalso _servicoConsultora;
late GoRouter roteador;

/// [cadastrada] = já existe registro em `consultoras` para a sessão.
Future<void> abrirApp(
  WidgetTester tester, {
  required bool logado,
  bool cadastrada = true,
  String nomeLogin = 'Ana Paula Consultora',
  List<ResumoParcelaDto> parcelas = const [],
}) async {
  usarTelaDeCelular(tester);
  _repositorio = _RepositorioFalso(logado: logado, nomeLogin: nomeLogin);
  _servicoConsultora = ServicoConsultoraFalso(
    registro: cadastrada ? dtoDeTeste(nome: 'Ana Paula Consultora') : null,
  );
  final consultoras = repositorioDeTeste(_servicoConsultora);
  final clientes = repositorioClientesDeTeste(
    ServicoClientesFalso(resumos: [resumoDto('c1', 'Mariana Souza')]),
  );
  final produtos = repositorioProdutosDeTeste(
    ServicoProdutosFalso(resumos: [produtoDto('p1', 'Kit Lily')]),
  );
  injetor
    ..registerSingleton<RepositorioAutenticacao>(_repositorio)
    ..registerSingleton<RepositorioConsultora>(consultoras)
    ..registerSingleton<RepositorioClientes>(clientes)
    ..registerSingleton<RepositorioVendas>(
      repositorioVendasDeTeste(
        ServicoVendasFalso(),
        produtos: produtos,
        clientes: clientes,
      ),
    )
    ..registerSingleton<RepositorioFornecedores>(
      repositorioFornecedoresDeTeste(
        ServicoFornecedoresFalso(resumos: [fornecedorDto('f1', 'Natura')]),
      ),
    )
    ..registerSingleton<RepositorioProdutos>(produtos)
    ..registerSingleton<RepositorioEstoque>(
      repositorioEstoqueDeTeste(ServicoEstoqueFalso(), produtos),
    )
    ..registerSingleton<RepositorioCategorias>(repositorioCategoriasDeTeste())
    ..registerSingleton<RepositorioServicos>(
      repositorioServicosDeTeste(
        ServicoServicosFalso(resumos: [servicoDto('s1', 'Manicure')]),
      ),
    )
    ..registerSingleton<RepositorioBoletos>(
      repositorioBoletosDeTeste(
        ServicoBoletosFalso(),
        fornecedores: injetor<RepositorioFornecedores>(),
      ),
    );
  // O Início (rota inicial) lê também parcelas, pagamentos e lembretes.
  final servicoVendas = ServicoVendasFalso(parcelas: List.of(parcelas));
  final servicoRecebimentos = ServicoRecebimentosFalso(vendas: servicoVendas);
  injetor
    ..registerSingleton<RepositorioRecebimentos>(
      repositorioRecebimentosDeTeste(
        vendas: servicoVendas,
        recebimentos: servicoRecebimentos,
        repositorioVendas: injetor<RepositorioVendas>(),
        clientes: clientes,
      ),
    )
    ..registerSingleton<RepositorioInicio>(
      repositorioInicioDeTeste(
        servico: ServicoInicioFalso(),
        recebimentos: servicoRecebimentos,
      ),
    );
  final acesso = NotificadorAcesso(
    autenticacao: _repositorio,
    consultoras: consultoras,
  );
  roteador = RoteadorApp.criar(acesso: acesso);
  addTearDown(() async {
    roteador.dispose();
    acesso.dispose();
    await injetor.reset();
  });
  await tester.pumpWidget(appDeTeste(roteador: roteador));
  await tester.pumpAndSettle();
}

Future<void> voltarDoSistema(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

/// Item da barra marcado como selecionado (acessibilidade).
bool estaSelecionado(WidgetTester tester, String rotulo) {
  final semantica = tester.getSemantics(find.bySemanticsLabel(rotulo).last);
  return containsSemantics(isSelected: true).matches(semantica, {});
}

void main() {
  group('controle de acesso', () {
    testWidgets('sem sessão abre o login com a marca e os botões sociais', (
      tester,
    ) async {
      await abrirApp(tester, logado: false);
      expect(
        find.image(const AssetImage('assets/imagens/logo.png')),
        findsWidgets,
      );
      expect(
        find.text('O app da consultora de beleza independente'),
        findsOneWidget,
      );
      expect(find.text('Continuar com Google'), findsOneWidget);
      expect(find.text('Continuar com Apple'), findsOneWidget);
    });

    testWidgets('sem sessão, pedir uma tela interna leva ao login', (
      tester,
    ) async {
      await abrirApp(tester, logado: false);
      roteador.go('/vendas');
      await tester.pumpAndSettle();
      expect(find.text('Continuar com Google'), findsOneWidget);
    });

    testWidgets('com sessão abre direto o Início', (tester) async {
      await abrirApp(tester, logado: true);
      expect(find.text('Alertas de hoje'), findsOneWidget);
      expect(find.text('Continuar com Google'), findsNothing);
    });

    testWidgets('com sessão, pedir o login leva ao Início', (tester) async {
      await abrirApp(tester, logado: true);
      roteador.go('/login');
      await tester.pumpAndSettle();
      expect(find.text('Alertas de hoje'), findsOneWidget);
    });

    testWidgets('ao entrar vai ao Início e o voltar não retorna ao login', (
      tester,
    ) async {
      await abrirApp(tester, logado: false);
      _repositorio.mudarSessao(true);
      await tester.pumpAndSettle();
      expect(find.text('Alertas de hoje'), findsOneWidget);

      await voltarDoSistema(tester);
      expect(find.text('Continuar com Google'), findsNothing);
    });

    testWidgets('sessão expirada em qualquer tela leva ao login', (
      tester,
    ) async {
      await abrirApp(tester, logado: true);
      roteador.go('/clientes');
      await tester.pumpAndSettle();

      _repositorio.mudarSessao(false);
      await tester.pumpAndSettle();
      expect(find.text('Continuar com Google'), findsOneWidget);

      await voltarDoSistema(tester);
      expect(find.text('Mariana Souza'), findsNothing);
    });
  });

  group('cadastro', () {
    testWidgets('primeiro login sem cadastro abre o cadastro', (tester) async {
      await abrirApp(tester, logado: true, cadastrada: false);
      expect(find.text('Qual é o seu número?'), findsOneWidget);
      expect(
        find.textContaining('Nome completo', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('sem cadastro, pedir Vendas leva ao cadastro', (tester) async {
      await abrirApp(tester, logado: true, cadastrada: false);
      roteador.go('/vendas');
      await tester.pumpAndSettle();
      expect(find.text('Qual é o seu número?'), findsOneWidget);
    });

    testWidgets('WhatsApp válido cadastra e abre o Início', (tester) async {
      await abrirApp(tester, logado: true, cadastrada: false);
      await tester.enterText(find.byType(TextField), '11987654321');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(
        _servicoConsultora.chamadas.last,
        'criar Ana Paula Consultora 11987654321',
      );
      expect(find.text('Alertas de hoje'), findsOneWidget);
    });

    testWidgets('WhatsApp inválido mostra o erro e não grava', (tester) async {
      await abrirApp(tester, logado: true, cadastrada: false);
      await tester.enterText(find.byType(TextField), '119876');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Informe o WhatsApp com DDD'), findsOneWidget);
      expect(
        _servicoConsultora.chamadas.where((c) => c.startsWith('criar')),
        isEmpty,
      );
    });

    testWidgets('falha ao gravar mantém os dados e mostra o erro', (
      tester,
    ) async {
      await abrirApp(tester, logado: true, cadastrada: false);
      _servicoConsultora.falharRede = true;
      await tester.enterText(find.byType(TextField), '11987654321');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('internet'), findsOneWidget);
      expect(find.text('(11) 98765-4321'), findsOneWidget);
      expect(find.text('Qual é o seu número?'), findsOneWidget);
    });

    testWidgets('login sem nome pede também o nome', (tester) async {
      await abrirApp(tester, logado: true, cadastrada: false, nomeLogin: '');
      expect(
        find.textContaining('Nome completo', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('voltar no cadastro encerra a sessão', (tester) async {
      await abrirApp(tester, logado: true, cadastrada: false);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(_repositorio.saidas, 1);
      expect(find.text('Continuar com Google'), findsOneWidget);
    });
  });

  group('verificação do cadastro', () {
    testWidgets(
      'sem internet mostra erro e tentar novamente segue para o Início',
      (tester) async {
        usarTelaDeCelular(tester);
        await abrirApp(tester, logado: false);
        _servicoConsultora.falharRede = true;
        _repositorio.mudarSessao(true);
        await tester.pumpAndSettle();

        expect(find.text('Tentar novamente'), findsOneWidget);
        expect(find.text('Qual é o seu número?'), findsNothing);

        _servicoConsultora.falharRede = false;
        await tester.tap(find.text('Tentar novamente'));
        await tester.pumpAndSettle();
        expect(find.text('Alertas de hoje'), findsOneWidget);
      },
    );
  });

  group('barra inferior', () {
    testWidgets('mostra os 5 itens na ordem, com Início ativo', (tester) async {
      await abrirApp(tester, logado: true);
      final rotulos = [
        'Produtos',
        'Clientes',
        'Início',
        'Vendas',
        'Financeiro',
      ];
      final posicoes = [
        for (final rotulo in rotulos)
          tester.getCenter(find.bySemanticsLabel(rotulo).last).dx,
      ];
      expect(posicoes, orderedEquals([...posicoes]..sort()));
      expect(estaSelecionado(tester, 'Início'), isTrue);
    });

    testWidgets('trocar de módulo pela barra marca o item', (tester) async {
      await abrirApp(tester, logado: true);
      await tester.tap(find.bySemanticsLabel('Clientes').last);
      await tester.pumpAndSettle();

      expect(find.text('Mariana Souza'), findsOneWidget);
      expect(estaSelecionado(tester, 'Clientes'), isTrue);
      expect(estaSelecionado(tester, 'Início'), isFalse);
    });

    testWidgets(
      'detalhe da cliente abre por cima (sem a barra) e voltar retorna à lista',
      (tester) async {
        await abrirApp(tester, logado: true);
        await tester.tap(find.bySemanticsLabel('Clientes').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Mariana Souza'));
        await tester.pumpAndSettle();
        expect(find.text('Detalhes do Cliente'), findsOneWidget);
        expect(find.bySemanticsLabel('Início'), findsNothing);

        await voltarDoSistema(tester);
        expect(find.text('Detalhes do Cliente'), findsNothing);
        expect(estaSelecionado(tester, 'Clientes'), isTrue);
      },
    );

    testWidgets(
      'Produtos mostra a lista; o detalhe abre por cima e voltar retorna',
      (tester) async {
        await abrirApp(tester, logado: true);
        await tester.tap(find.bySemanticsLabel('Produtos').last);
        await tester.pumpAndSettle();
        expect(find.text('1 produto'), findsOneWidget);
        expect(estaSelecionado(tester, 'Produtos'), isTrue);

        await tester.tap(find.text('Kit Lily'));
        await tester.pumpAndSettle();
        expect(find.text('Detalhes do Produto'), findsOneWidget);
        expect(find.bySemanticsLabel('Início'), findsNothing);

        await voltarDoSistema(tester);
        expect(find.text('Detalhes do Produto'), findsNothing);
        expect(estaSelecionado(tester, 'Produtos'), isTrue);
      },
    );

    testWidgets('Lançar estoque abre por cima (sem a barra) e voltar retorna', (
      tester,
    ) async {
      await abrirApp(tester, logado: true);
      await tester.tap(find.bySemanticsLabel('Produtos').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lançar estoque'));
      await tester.pumpAndSettle();
      expect(find.text('Lançar Estoque'), findsOneWidget);
      expect(find.bySemanticsLabel('Início'), findsNothing);

      await voltarDoSistema(tester);
      expect(find.text('1 produto'), findsOneWidget);
    });
  });

  group('menu lateral', () {
    Future<void> abrirMenu(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Abrir menu'));
      await tester.pumpAndSettle();
    }

    Future<void> rolarAte(WidgetTester tester, String texto) async {
      await tester.scrollUntilVisible(
        find.text(texto).hitTestable(),
        80,
        scrollable: find
            .descendant(
              of: find.byType(Drawer),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    }

    testWidgets('selo de cobranças atrasadas em A Receber', (tester) async {
      final ontem = DateTime.now().subtract(const Duration(days: 1));
      await abrirApp(
        tester,
        logado: true,
        parcelas: [
          parcelaDto('pa1', 'v1', vencimento: ontem),
          parcelaDto('pa2', 'v1', numero: 2, qtd: 2, vencimento: ontem),
          parcelaDto('paga', 'v2', pago: 24000, vencimento: ontem),
        ],
      );
      await abrirMenu(tester);
      await rolarAte(tester, 'Gestão financeira');
      await tester.tap(find.text('Gestão financeira'));
      await tester.pumpAndSettle();

      final selo = find.descendant(
        of: find.byType(Drawer),
        matching: find.bySemanticsLabel(RegExp('2 atrasadas')),
      );
      expect(selo, findsOneWidget);
    });

    testWidgets('sem parcelas atrasadas, sem selo', (tester) async {
      await abrirApp(tester, logado: true);
      await abrirMenu(tester);
      await rolarAte(tester, 'Gestão financeira');
      await tester.tap(find.text('Gestão financeira'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('atrasadas')), findsNothing);
    });

    testWidgets('menu abre com navegação principal fechada', (tester) async {
      await abrirApp(tester, logado: true);
      await abrirMenu(tester);

      expect(find.text('Navegação principal'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('Início')),
        findsNothing,
      );
    });

    testWidgets('mostra a consultora e destaca o item atual', (tester) async {
      await abrirApp(tester, logado: true);
      await abrirMenu(tester);

      expect(find.text('Ana Paula Consultora'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('AC')),
        findsOneWidget,
      );
      expect(find.textContaining('Sou Consultora v'), findsNothing);
      await rolarAte(tester, 'Navegação principal');
      await tester.tap(find.text('Navegação principal'));
      await tester.pumpAndSettle();
      final inicio = tester.widget<ItemMenuLateral>(
        find.widgetWithText(ItemMenuLateral, 'Início'),
      );
      expect(inicio.atual, isTrue);
    });

    testWidgets('navega, fecha o menu e não marca item da barra', (
      tester,
    ) async {
      await abrirApp(tester, logado: true);
      await abrirMenu(tester);
      await rolarAte(tester, 'Navegação principal');
      await tester.tap(find.text('Navegação principal'));
      await tester.pumpAndSettle();
      await rolarAte(tester, 'Fornecedores');
      await tester.tap(find.text('Fornecedores'));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
      expect(find.text('1 fornecedor'), findsOneWidget);
      expect(find.byType(BarraInferior), findsNothing);
    });

    testWidgets('Ver perfil e Configurações abrem o Perfil por cima', (
      tester,
    ) async {
      await abrirApp(tester, logado: true);
      await abrirMenu(tester);
      await tester.tap(find.text('Ver perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Meu Perfil'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Início'),
        findsNothing,
        reason: 'perfil abre sem a barra',
      );

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Alertas de hoje'), findsOneWidget);

      await abrirMenu(tester);
      await rolarAte(tester, 'Configurações');
      await tester.tap(find.text('Configurações'));
      await tester.pumpAndSettle();
      expect(find.text('Meu Perfil'), findsOneWidget);
    });

    testWidgets('editar o nome no perfil atualiza o menu', (tester) async {
      await abrirApp(tester, logado: true);
      await abrirMenu(tester);
      await tester.tap(find.text('Ver perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar Perfil'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Ana Paula Souza');
      await tester.tap(find.text('Salvar Alterações'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      await abrirMenu(tester);
      expect(find.text('Ana Paula Souza'), findsOneWidget);
    });

    testWidgets('sair pelo perfil encerra a sessão e mostra o login', (
      tester,
    ) async {
      await abrirApp(tester, logado: true);
      await abrirMenu(tester);
      await tester.tap(find.text('Ver perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair da Conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();

      expect(_repositorio.saidas, 1);
      expect(find.text('Continuar com Google'), findsOneWidget);
    });

    testWidgets('sair cancelado no perfil mantém a sessão', (tester) async {
      await abrirApp(tester, logado: true);
      await abrirMenu(tester);
      await tester.tap(find.text('Ver perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair da Conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(_repositorio.saidas, 0);
      expect(find.text('Continuar com Google'), findsNothing);
      expect(find.text('Meu Perfil'), findsOneWidget);
    });
  });

  group('botão voltar do sistema', () {
    testWidgets('com o menu aberto, fecha o menu e fica na tela', (
      tester,
    ) async {
      await abrirApp(tester, logado: true);
      roteador.go('/financeiro');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Abrir menu'));
      await tester.pumpAndSettle();

      await voltarDoSistema(tester);
      expect(find.byType(Drawer), findsNothing);
      expect(find.text('Categorias do Mês'), findsOneWidget);
    });

    testWidgets('em tela principal fora do Início, vai ao Início', (
      tester,
    ) async {
      await abrirApp(tester, logado: true);
      roteador.go('/financeiro');
      await tester.pumpAndSettle();

      await voltarDoSistema(tester);
      expect(find.text('Alertas de hoje'), findsOneWidget);
    });

    testWidgets('no Início, fecha o app', (tester) async {
      final chamadas = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (chamada) async {
          chamadas.add(chamada.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await abrirApp(tester, logado: true);
      await voltarDoSistema(tester);
      expect(chamadas, contains('SystemNavigator.pop'));
    });
  });
}
