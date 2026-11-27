// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/repository/repositorio_dicas.dart';
import 'package:sou_consultora/main.dart';

/// WhatsApp usado no cadastro quando a conta ainda não tem cadastro.
/// Troque com: --dart-define=E2E_WHATSAPP=11988887777
const whatsappE2E = String.fromEnvironment(
  'E2E_WHATSAPP',
  defaultValue: '11999990000',
);

/// Grupo a rodar (`--dart-define=E2E_GRUPO=E2E-04`). Vazio = todos.
/// Útil com `flutter drive`, que não aceita `--plain-name`.
const grupoE2E = String.fromEnvironment('E2E_GRUPO');

/// `skip` do grupo [codigo]: pula quando outro grupo foi escolhido em [grupoE2E].
bool pularGrupo(String codigo) => grupoE2E.isNotEmpty && grupoE2E != codigo;

/// Sobe o app real (Supabase de verdade) e espera sair da tela de carregamento.
Future<void> abrirApp(WidgetTester tester) async {
  await inicializarApp();
  // O passo a passo da primeira vez cobriria a tela e travaria os cenários.
  await injetor<RepositorioDicas>().marcarTodasComoVistas();
  await tester.pumpWidget(const MeuApp());
  await esperarAte(
    tester,
    find.byWidgetPredicate(
      (widget) => widget is Text && _telasDeEntrada.contains(widget.data),
    ),
    descricao: 'Início, Cadastro ou Login',
  );
  if (find.text('Continuar com Google').evaluate().isNotEmpty) {
    fail(
      'O app abriu no login. Entre manualmente com a conta de teste no aparelho e rode o E2E de novo.',
    );
  }
}

const _telasDeEntrada = {'Início', 'Cadastro', 'Continuar com Google'};

/// Avança frames até [alvo] aparecer (rede real: pumpAndSettle não espera requisições).
Future<void> esperarAte(
  WidgetTester tester,
  Finder alvo, {
  String? descricao,
  Duration limite = const Duration(seconds: 20),
}) async {
  final fim = DateTime.now().add(limite);
  while (DateTime.now().isBefore(fim)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (alvo.evaluate().isNotEmpty) return;
  }
  final textos = find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .toSet();
  fail(
    'Tempo esgotado esperando: ${descricao ?? alvo.describeMatch(Plurality.one)}.\nTextos na tela: $textos',
  );
}

/// Espera [alvo] sumir (ex.: "Salvando...").
Future<void> esperarSumir(
  WidgetTester tester,
  Finder alvo, {
  Duration limite = const Duration(seconds: 20),
}) async {
  final fim = DateTime.now().add(limite);
  while (DateTime.now().isBefore(fim)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (alvo.evaluate().isEmpty) return;
  }
  fail('Tempo esgotado esperando sumir: ${alvo.describeMatch(Plurality.one)}');
}

/// Arrasta a lista da tela do topo até [alvo] existir.
Future<void> mostrar(WidgetTester tester, Finder alvo) async {
  for (
    var tentativa = 0;
    tentativa < 10 && alvo.evaluate().isEmpty;
    tentativa++
  ) {
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -250));
    await tester.pumpAndSettle();
  }
}

Future<void> tocar(WidgetTester tester, Finder alvo) async {
  await mostrar(tester, alvo);
  await tester.ensureVisible(alvo.first);
  await tester.tap(alvo.first);
  await tester.pumpAndSettle();
}

/// Campo de texto pelo rótulo (ex.: "Nome completo").
Finder campo(String rotulo) {
  return find
      .ancestor(
        of: find.textContaining(rotulo, findRichText: true),
        matching: find.byType(TextField),
      )
      .first;
}

Future<void> digitar(WidgetTester tester, String rotulo, String texto) async {
  await mostrar(tester, find.textContaining(rotulo, findRichText: true));
  // Toca antes: depois de fechar uma folha o foco não vai sozinho ao campo.
  await tester.tap(campo(rotulo));
  await tester.pumpAndSettle();
  await tester.enterText(campo(rotulo), texto);
  await tester.pumpAndSettle();
}

Future<void> abrirMenu(WidgetTester tester) =>
    tocar(tester, find.byTooltip('Abrir menu'));

const _gruposDoMenu = {
  'Início': 'Navegação principal',
  'Vendas': 'Navegação principal',
  'Clientes': 'Navegação principal',
  'Produtos & Estoque': 'Navegação principal',
  'Serviços': 'Navegação principal',
  'Fornecedores': 'Navegação principal',
  'A Receber': 'Gestão financeira',
  'A Pagar': 'Gestão financeira',
  'Financeiro': 'Gestão financeira',
};

/// Item do menu lateral. Abre a categoria se ela estiver fechada e rola o menu.
Future<void> tocarNoMenu(WidgetTester tester, String item) async {
  final lista = find
      .descendant(of: find.byType(Drawer), matching: find.byType(Scrollable))
      .first;

  Future<bool> revelar(String texto) async {
    final alvo = find.text(texto).hitTestable();
    if (alvo.evaluate().isNotEmpty) return true;
    for (var tentativa = 0; tentativa < 8; tentativa++) {
      await tester.drag(lista, const Offset(0, 400));
      await tester.pumpAndSettle();
    }
    for (
      var tentativa = 0;
      tentativa < 8 && alvo.evaluate().isEmpty;
      tentativa++
    ) {
      await tester.drag(lista, const Offset(0, -150));
      await tester.pumpAndSettle();
    }
    return alvo.evaluate().isNotEmpty;
  }

  if (!await revelar(item)) {
    final grupo = _gruposDoMenu[item];
    if (grupo != null && await revelar(grupo)) {
      await tester.tap(find.text(grupo).hitTestable().first);
      await tester.pumpAndSettle();
    }
  }
  final visivel = await revelar(item);
  expect(visivel, isTrue, reason: 'item "$item" no menu');
  await tester.tap(find.text(item).hitTestable().first);
  await tester.pumpAndSettle();
}

Future<void> voltarDoSistema(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}
