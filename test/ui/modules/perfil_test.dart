// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/origem_foto.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_suporte.dart';
import 'package:sou_consultora/ui/modules/perfil/editar/editar_perfil_screen.dart';
import 'package:sou_consultora/ui/modules/perfil/meu_perfil/meu_perfil_screen.dart';

import '../../auxiliares/falsos_clientes.dart';
import '../../auxiliares/falsos_consultora.dart';
import '../../auxiliares/montar_app.dart';

class _AutenticacaoFalsa implements RepositorioAutenticacao {
  int saidas = 0;

  @override
  Future<Resultado<void>> sair() async {
    saidas++;
    return const Sucesso(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late ServicoConsultoraFalso _servico;
late FotoDispositivoFalsa _fotos;
late RepositorioConsultora _repositorio;
late _AutenticacaoFalsa _autenticacao;
late ServicoWhatsappFalso _whatsapp;

Future<void> abrirPerfil(
  WidgetTester tester, {
  String? chave,
  String? tipo,
  String? foto,
}) async {
  usarTelaDeCelular(tester);
  _servico = ServicoConsultoraFalso(
    registro: dtoDeTeste(
      nome: 'Ana Paula Silva',
      chave: chave,
      tipo: tipo,
      foto: foto,
    ),
  );
  _fotos = FotoDispositivoFalsa();
  _repositorio = repositorioDeTeste(_servico, _fotos);
  _autenticacao = _AutenticacaoFalsa();
  _whatsapp = ServicoWhatsappFalso();
  await _repositorio.buscarMinha();
  injetor
    ..registerSingleton<RepositorioConsultora>(_repositorio)
    ..registerSingleton<RepositorioAutenticacao>(_autenticacao)
    ..registerSingleton<RepositorioSuporte>(
      RepositorioSuporte(whatsapp: _whatsapp),
    );

  final roteador = GoRouter(
    initialLocation: '/perfil',
    routes: [
      GoRoute(
        path: '/perfil',
        builder: (_, _) => const MeuPerfilScreen(),
        routes: [
          GoRoute(
            path: 'editar',
            builder: (_, _) => const EditarPerfilScreen(),
          ),
        ],
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

/// Arrasta a lista da tela do topo até [alvo] existir (o ListView só constrói o visível).
Future<void> mostrar(WidgetTester tester, Finder alvo) async {
  for (
    var tentativa = 0;
    tentativa < 10 && alvo.evaluate().isEmpty;
    tentativa++
  ) {
    await tester.drag(find.byType(ListView).last, const Offset(0, -250));
    await tester.pumpAndSettle();
  }
}

Future<void> digitar(WidgetTester tester, String rotulo, String texto) async {
  await mostrar(tester, campo(rotulo));
  await tester.enterText(campo(rotulo), texto);
  await tester.pump();
}

Future<void> tocar(WidgetTester tester, Finder alvo) async {
  if (alvo.evaluate().isEmpty) await mostrar(tester, alvo);
  await tester.ensureVisible(alvo);
  await _subirAcimaDosBotoes(tester, alvo);
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

/// O `ensureVisible` aceita o item com só o topo à mostra; se o centro dele
/// estiver atrás dos botões fixos do rodapé, arrasta a lista até liberá-lo.
Future<void> _subirAcimaDosBotoes(WidgetTester tester, Finder alvo) async {
  final lista = find.byType(ListView).last;
  if (find.descendant(of: lista, matching: alvo).evaluate().isEmpty) return;
  final excesso =
      tester.getCenter(alvo.first).dy - tester.getRect(lista).bottom;
  if (excesso < 0) return;
  await tester.drag(lista, Offset(0, -(excesso + 60)));
  await tester.pumpAndSettle();
}

Finder campo(String rotulo) => find.ancestor(
  of: find.textContaining(rotulo, findRichText: true),
  matching: find.byType(TextField),
);

void main() {
  group('Meu perfil', () {
    testWidgets('mostra dados, WhatsApp formatado e chave Pix', (tester) async {
      await abrirPerfil(tester, chave: '+5511987654321', tipo: 'telefone');

      expect(find.text('Ana Paula Silva'), findsWidgets);
      expect(find.text('(11) 98765-4321'), findsNWidgets(2));
      expect(find.text('Tipo: Telefone'), findsNothing);
      expect(find.text('AS'), findsOneWidget);
    });

    testWidgets('sem chave Pix mostra "Não cadastrada" e não oferece copiar', (
      tester,
    ) async {
      await abrirPerfil(tester);
      expect(find.text('Não cadastrada'), findsOneWidget);
      expect(find.byTooltip('Copiar chave Pix'), findsNothing);
    });

    testWidgets('copiar a chave Pix avisa', (tester) async {
      String? copiado;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (chamada) async {
          if (chamada.method == 'Clipboard.setData') {
            copiado = (chamada.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await abrirPerfil(tester, chave: 'ana@email.com', tipo: 'email');
      await tocar(tester, find.byTooltip('Copiar chave Pix'));

      expect(copiado, 'ana@email.com');
      expect(find.text('Chave Pix copiada'), findsOneWidget);
    });

    testWidgets('Mais opções → Sair confirmado encerra a sessão', (
      tester,
    ) async {
      await abrirPerfil(tester);
      await tocar(tester, find.text('Mais opções'));
      await tocar(tester, find.text('Sair da Conta'));
      await tocar(tester, find.text('Sair'));
      expect(_autenticacao.saidas, 1);
    });

    testWidgets('Apagar conta abre o WhatsApp do suporte com o pedido', (
      tester,
    ) async {
      await abrirPerfil(tester);
      await tocar(tester, find.text('Mais opções'));
      expect(
        find.text('Pedir a exclusão ao suporte pelo WhatsApp'),
        findsOneWidget,
      );
      await tocar(tester, find.text('Apagar Conta'));

      expect(_whatsapp.aberturas, ['16991614062']);
      expect(
        _whatsapp.mensagens.single,
        'Quero apagar minha conta no app "Sou Consultora"',
      );
      // Não sai da conta nem apaga nada no app: quem apaga é o suporte.
      expect(_autenticacao.saidas, 0);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Meu Perfil'), findsOneWidget);
    });

    testWidgets('sem conseguir abrir o WhatsApp mostra o aviso', (
      tester,
    ) async {
      await abrirPerfil(tester);
      _whatsapp.abre = false;
      await tocar(tester, find.text('Mais opções'));
      await tocar(tester, find.text('Apagar Conta'));

      expect(find.text('Não foi possível abrir o WhatsApp'), findsOneWidget);
      expect(_autenticacao.saidas, 0);
      // O aviso some sozinho depois de um tempo.
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    });
  });

  group('Editar perfil', () {
    Future<void> abrirEdicao(
      WidgetTester tester, {
      String? chave,
      String? tipo,
    }) async {
      await abrirPerfil(tester, chave: chave, tipo: tipo);
      await tocar(tester, find.text('Editar Perfil'));
    }

    testWidgets('salvar grava e volta ao perfil atualizado', (tester) async {
      await abrirEdicao(tester);
      await digitar(tester, 'Nome completo', 'Ana Paula Souza');
      await tocar(tester, find.text('Salvar Alterações'));

      expect(find.text('Meu Perfil'), findsOneWidget);
      expect(find.text('Ana Paula Souza'), findsWidgets);
      expect(
        _servico.chamadas.last,
        'atualizar Ana Paula Souza 11987654321 null null',
      );
    });

    testWidgets('nome vazio mostra erro e não grava', (tester) async {
      await abrirEdicao(tester);
      await digitar(tester, 'Nome completo', ' ');
      await tocar(tester, find.text('Salvar Alterações'));

      expect(find.text('Informe o nome'), findsOneWidget);
      expect(
        _servico.chamadas.where((c) => c.startsWith('atualizar')),
        isEmpty,
      );
    });

    testWidgets('CPF inválido mostra erro', (tester) async {
      await abrirEdicao(tester);
      await tocar(tester, campo('Tipo de chave Pix'));
      await tocar(tester, find.text('CPF'));
      await digitar(tester, 'Chave Pix', '111.111.111-11');
      await tocar(tester, find.text('Salvar Alterações'));

      expect(find.text('CPF inválido'), findsOneWidget);
      expect(
        _servico.chamadas.where((c) => c.startsWith('atualizar')),
        isEmpty,
      );
    });

    testWidgets('CPF válido é gravado só com dígitos', (tester) async {
      await abrirEdicao(tester);
      await tocar(tester, campo('Tipo de chave Pix'));
      await tocar(tester, find.text('CPF'));
      await digitar(tester, 'Chave Pix', '529.982.247-25');
      await tocar(tester, find.text('Salvar Alterações'));

      expect(
        _servico.chamadas.last,
        'atualizar Ana Paula Silva 11987654321 52998224725 cpf',
      );
      expect(find.text('529.982.247-25'), findsOneWidget);
    });

    testWidgets('CPF inválido, depois trocar para e-mail, salva o e-mail', (
      tester,
    ) async {
      await abrirEdicao(tester);
      await tocar(tester, campo('Tipo de chave Pix'));
      await tocar(tester, find.text('CPF'));
      await digitar(tester, 'Chave Pix', '111.111.111-11');
      await tocar(tester, find.text('Salvar Alterações'));
      expect(find.text('CPF inválido'), findsOneWidget);

      await tocar(tester, campo('Tipo de chave Pix'));
      await tocar(tester, find.text('E-mail'));
      await digitar(tester, 'Chave Pix', 'e2e@souconsultora.app');
      await tocar(tester, find.text('Salvar Alterações'));

      expect(find.text('Meu Perfil'), findsOneWidget);
      expect(
        _servico.chamadas.last,
        'atualizar Ana Paula Silva 11987654321 e2e@souconsultora.app email',
      );
    });

    testWidgets('chave sem tipo pede o tipo', (tester) async {
      await abrirEdicao(tester);
      await digitar(tester, 'Chave Pix', 'ana@email.com');
      await tocar(tester, find.text('Salvar Alterações'));
      expect(find.text('Escolha o tipo da chave'), findsOneWidget);
    });

    testWidgets('chave vazia com tipo escolhido pede a chave e não grava', (
      tester,
    ) async {
      await abrirEdicao(tester, chave: 'ana@email.com', tipo: 'email');
      await digitar(tester, 'Chave Pix', '');
      await tocar(tester, find.text('Salvar Alterações'));

      expect(find.text('Informe a chave Pix'), findsOneWidget);
      expect(
        _servico.chamadas.where((c) => c.startsWith('atualizar')),
        isEmpty,
      );
    });

    testWidgets('cancelar descarta as alterações', (tester) async {
      await abrirEdicao(tester);
      await digitar(tester, 'Telefone / WhatsApp', '21999998888');
      // Sem botão Cancelar: a seta do cabeçalho descarta e volta.
      expect(find.text('Cancelar'), findsNothing);
      await tocar(tester, find.byTooltip('Voltar'));

      expect(find.text('Meu Perfil'), findsOneWidget);
      expect(find.text('(11) 98765-4321'), findsOneWidget);
      expect(
        _servico.chamadas.where((c) => c.startsWith('atualizar')),
        isEmpty,
      );
    });
  });

  group('Foto do perfil', () {
    testWidgets('escolher da galeria envia e mostra a nova foto', (
      tester,
    ) async {
      await abrirPerfil(tester);
      await tocar(tester, find.byTooltip('Alterar foto'));
      await tocar(tester, find.text('Escolher da galeria'));

      expect(_fotos.ultimaOrigem, OrigemFoto.galeria);
      expect(_servico.chamadas, contains('enviarFoto'));
      expect(_repositorio.atual?.caminhoFoto, 'id-ana/perfil-1.jpg');
    });

    testWidgets('desistir no recorte mantém a foto anterior', (tester) async {
      await abrirPerfil(tester, foto: 'id-ana/perfil-antiga.jpg');
      _fotos.resposta = const Sucesso(null);
      await tocar(tester, find.byTooltip('Alterar foto'));
      await tocar(tester, find.text('Tirar foto'));

      expect(_fotos.ultimaOrigem, OrigemFoto.camera);
      expect(_servico.chamadas, isNot(contains('enviarFoto')));
      expect(_repositorio.atual?.caminhoFoto, 'id-ana/perfil-antiga.jpg');
    });

    testWidgets('falha no envio mostra erro e mantém a foto anterior', (
      tester,
    ) async {
      await abrirPerfil(tester, foto: 'id-ana/perfil-antiga.jpg');
      _servico.falharRede = true;
      await tocar(tester, find.byTooltip('Alterar foto'));
      await tocar(tester, find.text('Escolher da galeria'));

      expect(find.textContaining('internet'), findsOneWidget);
      expect(_repositorio.atual?.caminhoFoto, 'id-ana/perfil-antiga.jpg');
    });

    testWidgets('remover foto volta às iniciais', (tester) async {
      await abrirPerfil(tester, foto: 'id-ana/perfil-1.jpg');
      await tocar(tester, find.byTooltip('Alterar foto'));
      await tocar(tester, find.text('Remover foto'));

      expect(_repositorio.atual?.caminhoFoto, isNull);
      expect(_servico.fotosRemovidas, ['id-ana/perfil-1.jpg']);
    });

    testWidgets('sem foto, a folha não oferece remover', (tester) async {
      await abrirPerfil(tester);
      await tocar(tester, find.byTooltip('Alterar foto'));
      expect(find.text('Remover foto'), findsNothing);
    });

    testWidgets('na edição, "Alterar foto" abre a mesma folha', (tester) async {
      await abrirPerfil(tester);
      await tocar(tester, find.text('Editar Perfil'));
      await tocar(tester, find.text('Alterar foto'));
      expect(find.text('Foto do Perfil'), findsOneWidget);
    });
  });
}
