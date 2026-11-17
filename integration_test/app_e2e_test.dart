// ignore_for_file: deprecated_member_use
//
// Testes E2E do Sou Consultora — rodam no app real, contra o Supabase real.
// Como rodar e o que conferir à mão: integration_test/README.md
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';

import 'auxiliares_e2e.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ————————————————————————————————————————————————————————————————
  // E2E-01 · Acesso
  // ————————————————————————————————————————————————————————————————
  group('E2E-01 Acesso', () {
    testWidgets('com sessão salva, abre no Início ou no Cadastro (nunca no login)', (tester) async {
      await abrirApp(tester);
      expect(find.text('Continuar com Google'), findsNothing);
    });

    testWidgets('primeiro acesso: WhatsApp inválido é recusado e o válido cadastra', (tester) async {
      await abrirApp(tester);
      if (find.text('Qual é o seu número?').evaluate().isEmpty) {
        markTestSkipped('Conta já cadastrada — cenário de primeiro acesso não se aplica.');
        return;
      }

      await digitar(tester, 'Número de WhatsApp', '119876');
      await tocar(tester, find.text('Continuar'));
      expect(find.text('Informe o WhatsApp com DDD'), findsOneWidget);

      await digitar(tester, 'Número de WhatsApp', whatsappE2E);
      await tocar(tester, find.text('Continuar'));
      await esperarAte(tester, find.text('Início'), descricao: 'Início após o cadastro');
      expect(injetor<RepositorioConsultora>().atual?.whatsapp, whatsappE2E);
    });
  });

  // ————————————————————————————————————————————————————————————————
  // E2E-02 · Navegação
  // ————————————————————————————————————————————————————————————————
  group('E2E-02 Navegação', () {
    testWidgets('barra inferior abre os 5 módulos', (tester) async {
      await abrirApp(tester);
      for (final modulo in ['Produtos', 'Clientes', 'Vendas', 'Financeiro', 'Início']) {
        await tester.tap(find.bySemanticsLabel(modulo).last);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(Material, modulo), findsWidgets, reason: modulo);
      }
    });

    testWidgets('menu lateral: consultora, item atual e navegação', (tester) async {
      await abrirApp(tester);
      final consultora = injetor<RepositorioConsultora>().atual!;

      await abrirMenu(tester);
      expect(find.text(consultora.nome), findsWidgets);
      expect(find.textContaining('Sou Consultora v'), findsOneWidget);

      await tocarNoMenu(tester, 'Fornecedores & Marcas');
      expect(find.byType(Drawer), findsNothing);
      expect(find.text('Fornecedores'), findsWidgets);
    });

    testWidgets('voltar do sistema: tela principal → Início', (tester) async {
      await abrirApp(tester);
      await tester.tap(find.bySemanticsLabel('Vendas').last);
      await tester.pumpAndSettle();

      await voltarDoSistema(tester);
      expect(find.text('Início'), findsWidgets);
    });
  });

  // ————————————————————————————————————————————————————————————————
  // E2E-03 · Perfil (restaura os dados originais no fim, mesmo se falhar)
  // ————————————————————————————————————————————————————————————————
  group('E2E-03 Perfil', () {
    late Consultora original;

    Future<void> abrirPerfil(WidgetTester tester) async {
      await abrirApp(tester);
      original = injetor<RepositorioConsultora>().atual!;
      addTearDown(() => injetor<RepositorioConsultora>().atualizar(
            nome: original.nome,
            whatsapp: original.whatsapp,
            chavePix: original.chavePix,
          ));
      await abrirMenu(tester);
      await tocar(tester, find.text('Ver perfil'));
      await esperarAte(tester, find.text('Meu Perfil'));
    }

    Future<void> salvar(WidgetTester tester) async {
      await tocar(tester, find.text('Salvar Alterações'));
      await esperarAte(tester, find.text('Meu Perfil'), descricao: 'volta ao perfil após salvar');
    }

    testWidgets('mostra os dados e abre por cima (sem a barra)', (tester) async {
      await abrirPerfil(tester);
      expect(find.text(original.nome), findsWidgets);
      expect(find.text('Editar Perfil'), findsOneWidget);
      expect(find.bySemanticsLabel('Produtos'), findsNothing);

      await tocar(tester, find.byTooltip('Voltar'));
      expect(find.bySemanticsLabel('Produtos'), findsWidgets);
    });

    testWidgets('editar o nome grava no banco e atualiza o menu', (tester) async {
      await abrirPerfil(tester);
      final novoNome = '${original.nome} E2E';

      await tocar(tester, find.text('Editar Perfil'));
      await digitar(tester, 'Nome completo', novoNome);
      await salvar(tester);
      expect(find.text(novoNome), findsWidgets);

      // Relê do banco: confirma que gravou de verdade (não só na tela).
      final relido = await injetor<RepositorioConsultora>().buscarMinha();
      expect(relido, isA<Sucesso<Consultora?>>());
      expect(injetor<RepositorioConsultora>().atual?.nome, novoNome);

      await tocar(tester, find.byTooltip('Voltar'));
      await abrirMenu(tester);
      expect(find.text(novoNome), findsWidgets);
    });

    testWidgets('chave Pix: CPF inválido é recusado; e-mail é salvo e copiado', (tester) async {
      await abrirPerfil(tester);

      await tocar(tester, find.text('Editar Perfil'));
      await tocar(tester, campo('Tipo de chave Pix'));
      await tocar(tester, find.text('CPF'));
      await digitar(tester, 'Chave Pix', '111.111.111-11');
      await tocar(tester, find.text('Salvar Alterações'));
      expect(find.text('CPF inválido'), findsOneWidget);

      await tocar(tester, campo('Tipo de chave Pix'));
      await tocar(tester, find.text('E-mail'));
      await digitar(tester, 'Chave Pix', 'e2e@souconsultora.app');
      await salvar(tester);
      expect(find.text('Tipo: E-mail'), findsOneWidget);
      expect(find.text('e2e@souconsultora.app'), findsOneWidget);

      await tocar(tester, find.byTooltip('Copiar chave Pix'));
      expect(find.text('Chave Pix copiada'), findsOneWidget);
    });

    testWidgets('cancelar a edição não grava', (tester) async {
      await abrirPerfil(tester);
      await tocar(tester, find.text('Editar Perfil'));
      await digitar(tester, 'Nome completo', 'Nome que não deve ficar');
      await tocar(tester, find.text('Cancelar'));

      expect(find.text('Meu Perfil'), findsOneWidget);
      expect(find.text('Nome que não deve ficar'), findsNothing);
    });

    testWidgets('folha da foto oferece câmera e galeria (o fluxo nativo é manual)', (tester) async {
      await abrirPerfil(tester);
      await tocar(tester, find.byTooltip('Alterar foto'));
      expect(find.text('Foto do Perfil'), findsOneWidget);
      expect(find.text('Tirar foto'), findsOneWidget);
      expect(find.text('Escolher da galeria'), findsOneWidget);
      await tocar(tester, find.byTooltip('Fechar'));
    });

    testWidgets('sair pede confirmação (o teste cancela para manter a sessão)', (tester) async {
      await abrirPerfil(tester);
      await tocar(tester, find.text('Mais opções'));
      await tocar(tester, find.text('Sair da Conta'));
      expect(find.text('Sair da conta?'), findsOneWidget);

      await tocar(tester, find.text('Cancelar'));
      expect(find.text('Meu Perfil'), findsOneWidget);
    });
  });
}
