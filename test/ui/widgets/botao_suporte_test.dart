import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/env/suporte_app.dart';
import 'package:sou_consultora/core/repository/repositorio_suporte.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_suporte/botao_suporte_cubit.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';

import '../../auxiliares/falsos_clientes.dart';
import '../../auxiliares/falsos_consultora.dart';

Widget _tela(Widget filho) => MaterialApp(home: Scaffold(body: filho));

void main() {
  group('EstadoErroApp', () {
    testWidgets('mostra "Tentar novamente" e o suporte logo abaixo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _tela(EstadoErroApp(mensagem: 'Sem rede', onTentarNovamente: () {})),
      );

      expect(find.text('Algo deu errado'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.text('Falar com o suporte'), findsOneWidget);
      final tentar = tester.getTopLeft(find.text('Tentar novamente')).dy;
      final suporte = tester.getTopLeft(find.text('Falar com o suporte')).dy;
      expect(suporte, greaterThan(tentar));
    });

    testWidgets('sem "Tentar novamente" o suporte aparece do mesmo jeito', (
      tester,
    ) async {
      await tester.pumpWidget(_tela(const EstadoErroApp(mensagem: 'Erro')));

      expect(find.text('Tentar novamente'), findsNothing);
      expect(find.text('Falar com o suporte'), findsOneWidget);
    });
  });

  group('BotaoSuporteCubit', () {
    test('abre o WhatsApp do suporte com o erro na mensagem', () async {
      final whatsapp = ServicoWhatsappFalso();
      final cubit = BotaoSuporteCubit(
        suporte: RepositorioSuporte(whatsapp: whatsapp),
        consultora: repositorioDeTeste(ServicoConsultoraFalso()),
      );

      await cubit.abrir(detalhe: 'Não foi possível carregar as clientes.');

      expect(whatsapp.aberturas, [SuporteApp.whatsapp]);
      expect(
        whatsapp.mensagens.single,
        contains('Erro: Não foi possível carregar as clientes.'),
      );
      expect(cubit.state.abrindo, isFalse);
      expect(cubit.state.erro, isNull);
      await cubit.close();
    });

    test('WhatsApp que não abre devolve o erro para o botão mostrar', () async {
      final whatsapp = ServicoWhatsappFalso()..abre = false;
      final cubit = BotaoSuporteCubit(
        suporte: RepositorioSuporte(whatsapp: whatsapp),
        consultora: repositorioDeTeste(ServicoConsultoraFalso()),
      );

      await cubit.abrir(detalhe: 'x');

      expect(cubit.state.erro, isNotNull);
      expect(cubit.state.abrindo, isFalse);
      await cubit.close();
    });
  });
}
