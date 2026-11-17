// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/foto_quadrada_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_flutuante_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_icone_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';
import 'package:sou_consultora/ui/widgets/cards/grupo_navegacao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/dialogo_confirmacao_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';

import '../../auxiliares/montar_app.dart';

void main() {
  testWidgets('botões flutuante e de ícone respondem ao toque', (tester) async {
    var toques = 0;
    await montar(
      tester,
      Column(
        children: [
          BotaoFlutuanteApp(rotulo: 'Novo cliente', onPressed: () => toques++),
          BotaoIconeApp(dica: 'Abrir cadastro', onPressed: () => toques++),
        ],
      ),
    );

    await tester.tap(find.text('Novo cliente'));
    await tester.tap(find.byTooltip('Abrir cadastro'));
    expect(toques, 2);
  });

  testWidgets('card de lista mostra dados, selo e responde ao toque', (tester) async {
    var tocou = false;
    await montar(
      tester,
      CartaoListaApp(
        titulo: 'Dona Carla',
        subtitulo: 'Última compra há 3 dias',
        inicio: const AvatarApp(iniciais: 'DC'),
        selo: const SeloStatusApp(rotulo: 'Deve R\$ 120', status: StatusSelo.perigo),
        onTap: () => tocou = true,
      ),
    );

    expect(find.text('Dona Carla'), findsOneWidget);
    expect(find.text('Deve R\$ 120'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    await tester.tap(find.text('Dona Carla'));
    expect(tocou, isTrue);
  });

  testWidgets('grupo de navegação aciona o item tocado', (tester) async {
    String? aberto;
    await montar(
      tester,
      GrupoNavegacaoApp(
        itens: [
          ItemNavegacaoApp(icone: Icons.badge_outlined, titulo: 'Dados Cadastrais', onTap: () => aberto = 'dados'),
          ItemNavegacaoApp(icone: Icons.shopping_bag_outlined, titulo: 'Compras da Cliente', onTap: () => aberto = 'compras'),
        ],
      ),
    );

    await tester.tap(find.text('Compras da Cliente'));
    expect(aberto, 'compras');
  });

  testWidgets('avatar sem foto mostra as iniciais', (tester) async {
    await montar(tester, const Column(children: [AvatarApp(iniciais: 'AC'), AvatarApp(urlImagem: ' ', iniciais: 'DC')]));
    expect(find.text('AC'), findsOneWidget);
    expect(find.text('DC'), findsOneWidget);
  });

  testWidgets('foto quadrada sem url mostra reserva em 1:1', (tester) async {
    await montar(tester, const Center(child: FotoQuadradaApp(tamanho: TamanhoAvatar.destaque)));

    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(tester.getSize(find.byType(FotoQuadradaApp)), const Size(80, 80));
  });

  testWidgets('diálogo devolve true ao confirmar e false ao cancelar', (tester) async {
    final respostas = <bool>[];
    await montar(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => respostas.add(
            await DialogoConfirmacaoApp.mostrar(context: context, titulo: 'Sair', mensagem: 'Deseja sair?', rotuloConfirmar: 'Sair', perigo: true),
          ),
          child: const Text('abrir'),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(respostas, [true, false]);
  });

  testWidgets('folha inferior mostra título e fecha', (tester) async {
    await montar(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => FolhaInferiorApp.mostrar<void>(
            context: context,
            titulo: 'Opções da parcela',
            subtitulo: 'Parcela 2 de 2',
            conteudo: (_) => const Text('Cobrar no WhatsApp'),
          ),
          child: const Text('abrir'),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Opções da parcela'), findsOneWidget);
    expect(find.text('Cobrar no WhatsApp'), findsOneWidget);

    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    expect(find.text('Opções da parcela'), findsNothing);
  });

  testWidgets('estados: vazio, erro com tentar novamente e em construção', (tester) async {
    var tentou = false;
    await montar(
      tester,
      Column(
        children: [
          const EstadoVazioApp(titulo: 'Nenhum cliente'),
          EstadoErroApp(mensagem: 'Sem conexão', onTentarNovamente: () => tentou = true),
          const EstadoEmConstrucaoApp(modulo: 'A Pagar'),
        ],
      ),
    );

    expect(find.text('Nenhum cliente'), findsOneWidget);
    expect(find.text('A Pagar em construção'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    expect(tentou, isTrue);
  });
}
