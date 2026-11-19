import 'package:flutter/widgets.dart' show EditableText;
import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/model/resumo_consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/ui/modules/cadastro/cadastro_screen.dart';

import '../../auxiliares/falsos_consultora.dart';
import '../../auxiliares/falsos_fornecedores.dart';
import '../../auxiliares/montar_app.dart';

class _AutenticacaoFalsa implements RepositorioAutenticacao {
  @override
  ResumoConsultora resumoDaConsultora() =>
      const ResumoConsultora(nome: 'Ana Paula');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => injetor.reset());

  testWidgets('mostra as 6 marcas e cadastra só as marcadas', (tester) async {
    final fornecedores = ServicoFornecedoresFalso();
    injetor
      ..registerSingleton<RepositorioAutenticacao>(_AutenticacaoFalsa())
      ..registerSingleton<RepositorioConsultora>(
        repositorioDeTeste(ServicoConsultoraFalso(), null, fornecedores),
      );
    await tester.pumpWidget(appDeTeste(home: const CadastroScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Quais marcas você vende?'), findsOneWidget);
    for (final nome in [
      'Natura',
      'Avon',
      'O Boticário',
      'Eudora',
      'Tupperware',
      'Mary Kay',
    ]) {
      expect(find.text(nome), findsOneWidget, reason: nome);
    }

    await tester.tap(find.text('Eudora'));
    await tester.tap(find.text('Avon'));
    await tester.tap(find.text('Avon')); // desmarca
    await tester.pump();
    await tester.enterText(find.byType(EditableText).first, '11987654321');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(fornecedores.salvos.map((s) => s.fornecedor.nome), ['Eudora']);
  });
}
