import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/ui/modules/produtos/lista/widgets/cartao_produto.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';

import '../../auxiliares/falsos_produtos.dart';
import '../../auxiliares/montar_app.dart';

void main() {
  test('o selo muda de cor conforme o estoque', () {
    expect(
      CartaoProduto.statusDoEstoque(SituacaoEstoque.emEstoque),
      StatusSelo.sucesso,
    );
    expect(
      CartaoProduto.statusDoEstoque(SituacaoEstoque.baixo),
      StatusSelo.alerta,
    );
    expect(
      CartaoProduto.statusDoEstoque(SituacaoEstoque.esgotado),
      StatusSelo.perigo,
    );
  });

  testWidgets('mostra o estoque num selo colorido, com texto curto', (
    tester,
  ) async {
    Future<void> mostrar(int qtd) => montar(
      tester,
      CartaoProduto(
        produto: produtoDto('p1', 'Kit Lily', qtdDisponivel: qtd).paraModel(),
        onTap: () {},
      ),
    );

    await mostrar(8);
    expect(find.byType(SeloStatusApp), findsOneWidget);
    expect(find.text('8 un'), findsOneWidget);

    await mostrar(1);
    expect(find.text('1 un (baixo)'), findsOneWidget);

    await mostrar(0);
    expect(find.text('Esgotado'), findsOneWidget);
  });
}
