import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/repository/repositorio_versao.dart';
import 'package:sou_consultora/ui/modules/atualizacao/atualizacao_cubit.dart';
import 'package:sou_consultora/ui/modules/atualizacao/atualizacao_screen.dart';
import 'package:sou_consultora/ui/modules/atualizacao/atualizacao_state.dart';

import '../../auxiliares/montar_app.dart';

class _VersaoFalsa implements RepositorioVersao {
  _VersaoFalsa({this.falha});
  final FalhaApp? falha;
  int aberturas = 0;

  @override
  Future<Resultado<void>> abrirLoja() async {
    aberturas++;
    return falha == null ? const Sucesso(null) : Erro(falha!);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => injetor.reset());

  testWidgets('mostra o aviso e abre a loja ao tocar em Atualizar agora', (
    tester,
  ) async {
    final versao = _VersaoFalsa();
    injetor.registerSingleton<RepositorioVersao>(versao);
    await tester.pumpWidget(appDeTeste(home: const AtualizacaoScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Atualização necessária'), findsOneWidget);
    await tester.tap(find.text('Atualizar agora'));
    await tester.pumpAndSettle();
    expect(versao.aberturas, 1);
  });

  test('link da loja indisponível emite erro e volta ao inicial', () async {
    final cubit = AtualizacaoCubit(
      repositorio: _VersaoFalsa(
        falha: const FalhaInesperada('Link da loja não configurado.'),
      ),
    );
    final estados = <AtualizacaoState>[];
    final assinatura = cubit.stream.listen(estados.add);

    await cubit.abrirLoja();
    cubit.limparErro();
    await Future<void>.delayed(Duration.zero);

    expect(estados[0], isA<AtualizacaoAbrindoLoja>());
    expect(
      (estados[1] as AtualizacaoErro).mensagem,
      'Link da loja não configurado.',
    );
    expect(estados[2], isA<AtualizacaoInicial>());
    await assinatura.cancel();
    await cubit.close();
  });
}
