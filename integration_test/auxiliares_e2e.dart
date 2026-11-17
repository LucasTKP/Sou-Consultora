// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/main.dart';

/// WhatsApp usado no cadastro quando a conta ainda não tem cadastro.
/// Troque com: --dart-define=E2E_WHATSAPP=11988887777
const whatsappE2E = String.fromEnvironment('E2E_WHATSAPP', defaultValue: '11999990000');

/// Sobe o app real (Supabase de verdade) e espera sair da tela de carregamento.
Future<void> abrirApp(WidgetTester tester) async {
  await inicializarApp();
  await tester.pumpWidget(const MeuApp());
  await esperarAte(
    tester,
    find.byWidgetPredicate((widget) => widget is Text && _telasDeEntrada.contains(widget.data)),
    descricao: 'Início, Cadastro ou Login',
  );
  if (find.text('Continuar com Google').evaluate().isNotEmpty) {
    fail('O app abriu no login. Entre manualmente com a conta de teste no aparelho e rode o E2E de novo.');
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
  final textos = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().toSet();
  fail('Tempo esgotado esperando: ${descricao ?? alvo.describeMatch(Plurality.one)}.\nTextos na tela: $textos');
}

/// Espera [alvo] sumir (ex.: "Salvando...").
Future<void> esperarSumir(WidgetTester tester, Finder alvo, {Duration limite = const Duration(seconds: 20)}) async {
  final fim = DateTime.now().add(limite);
  while (DateTime.now().isBefore(fim)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (alvo.evaluate().isEmpty) return;
  }
  fail('Tempo esgotado esperando sumir: ${alvo.describeMatch(Plurality.one)}');
}

/// Arrasta a lista da tela do topo até [alvo] existir.
Future<void> mostrar(WidgetTester tester, Finder alvo) async {
  for (var tentativa = 0; tentativa < 10 && alvo.evaluate().isEmpty; tentativa++) {
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
  return find.ancestor(of: find.textContaining(rotulo, findRichText: true), matching: find.byType(TextField)).first;
}

Future<void> digitar(WidgetTester tester, String rotulo, String texto) async {
  await mostrar(tester, find.textContaining(rotulo, findRichText: true));
  await tester.enterText(campo(rotulo), texto);
  await tester.pumpAndSettle();
}

Future<void> abrirMenu(WidgetTester tester) => tocar(tester, find.byTooltip('Abrir menu'));

/// Item do menu lateral (rola o menu se preciso).
Future<void> tocarNoMenu(WidgetTester tester, String item) async {
  final alvo = find.text(item).hitTestable();
  final lista = find.descendant(of: find.byType(Drawer), matching: find.byType(Scrollable)).first;
  for (var tentativa = 0; tentativa < 6 && alvo.evaluate().isEmpty; tentativa++) {
    await tester.drag(lista, const Offset(0, -150));
    await tester.pumpAndSettle();
  }
  await tester.tap(alvo.first);
  await tester.pumpAndSettle();
}

Future<void> voltarDoSistema(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}
