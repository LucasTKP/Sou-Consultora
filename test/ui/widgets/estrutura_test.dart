// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';

import '../../auxiliares/montar_app.dart';

void main() {
  testWidgets('cabeçalho mostra título, subtítulo e aciona o menu', (
    tester,
  ) async {
    var abriuMenu = false;
    await montar(
      tester,
      CabecalhoApp(
        titulo: 'Nova Venda',
        subtitulo: 'Passo 1 de 2',
        acao: AcaoCabecalho.menu,
        onMenu: () => abriuMenu = true,
      ),
    );

    expect(find.text('Nova Venda'), findsOneWidget);
    expect(find.text('PASSO 1 DE 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Abrir menu'));
    expect(abriuMenu, isTrue);
  });

  testWidgets('cabeçalho com voltar chama o callback', (tester) async {
    var voltou = false;
    await montar(
      tester,
      CabecalhoApp(titulo: 'Detalhes', onVoltar: () => voltou = true),
    );

    await tester.tap(find.byTooltip('Voltar'));
    expect(voltou, isTrue);
  });

  testWidgets('cabeçalho sem ação não mostra botões', (tester) async {
    await montar(
      tester,
      const CabecalhoApp(titulo: 'Início', acao: AcaoCabecalho.nenhuma),
    );
    expect(find.byType(IconButton), findsNothing);
  });
}
