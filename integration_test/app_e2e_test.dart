// ignore_for_file: deprecated_member_use
//
// Testes E2E do Sou Consultora — rodam no app real, contra o Supabase real.
// Como rodar e o que conferir à mão: integration_test/README.md
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/resumo_financeiro.dart';
import 'package:sou_consultora/core/model/resumo_inicio.dart';
import 'package:sou_consultora/core/repository/repositorio_boletos.dart';
import 'package:sou_consultora/core/repository/repositorio_clientes.dart';
import 'package:sou_consultora/core/repository/repositorio_consultora.dart';
import 'package:sou_consultora/core/model/fornecedor.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/core/repository/repositorio_inicio.dart';
import 'package:sou_consultora/core/repository/repositorio_estoque.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/core/repository/repositorio_servicos.dart';
import 'package:sou_consultora/core/repository/repositorio_vendas.dart';
import 'package:sou_consultora/core/model/item_venda.dart';
import 'package:sou_consultora/core/model/pedido_venda.dart';
import 'package:sou_consultora/core/model/plano_parcelas.dart';
import 'package:sou_consultora/core/repository/repositorio_recebimentos.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_data_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_moeda_app.dart';

import 'auxiliares_e2e.dart';

/// Fornecedor fixo dos grupos E2E-05 e E2E-06 (o mesmo dado nos dois).
final fornecedorE2e = Fornecedor(
  nome: 'E2E Fornecedor',
  ramo: 'Teste automatizado',
  telefone: '11999990002',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ————————————————————————————————————————————————————————————————
  // E2E-01 · Acesso
  // ————————————————————————————————————————————————————————————————
  group('E2E-01 Acesso', () {
    testWidgets(
      'com sessão salva, abre no Início ou no Cadastro (nunca no login)',
      (tester) async {
        await abrirApp(tester);
        expect(find.text('Continuar com Google'), findsNothing);
      },
    );

    testWidgets(
      'primeiro acesso: WhatsApp inválido é recusado e o válido cadastra',
      (tester) async {
        await abrirApp(tester);
        if (find.text('Qual é o seu número?').evaluate().isEmpty) {
          markTestSkipped(
            'Conta já cadastrada — cenário de primeiro acesso não se aplica.',
          );
          return;
        }

        await digitar(tester, 'Número de WhatsApp', '119876');
        await tocar(tester, find.text('Continuar'));
        expect(find.text('Informe o WhatsApp com DDD'), findsOneWidget);

        await digitar(tester, 'Número de WhatsApp', whatsappE2E);
        await tocar(tester, find.text('Continuar'));
        await esperarAte(
          tester,
          find.text('Início'),
          descricao: 'Início após o cadastro',
        );
        expect(injetor<RepositorioConsultora>().atual?.whatsapp, whatsappE2E);
      },
    );
  }, skip: pularGrupo('E2E-01'));

  // ————————————————————————————————————————————————————————————————
  // E2E-02 · Navegação
  // ————————————————————————————————————————————————————————————————
  group('E2E-02 Navegação', () {
    testWidgets('barra inferior abre os 5 módulos', (tester) async {
      await abrirApp(tester);
      for (final modulo in [
        'Produtos',
        'Clientes',
        'Vendas',
        'Financeiro',
        'Início',
      ]) {
        await tester.tap(find.bySemanticsLabel(modulo).last);
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(Material, modulo),
          findsWidgets,
          reason: modulo,
        );
      }
    });

    testWidgets('menu lateral: consultora, item atual e navegação', (
      tester,
    ) async {
      await abrirApp(tester);
      final consultora = injetor<RepositorioConsultora>().atual!;

      await abrirMenu(tester);
      expect(find.text(consultora.nome), findsWidgets);
      expect(find.textContaining('Sou Consultora v'), findsNothing);

      await tocarNoMenu(tester, 'Fornecedores');
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
  }, skip: pularGrupo('E2E-02'));

  // ————————————————————————————————————————————————————————————————
  // E2E-03 · Perfil (restaura os dados originais no fim, mesmo se falhar)
  // ————————————————————————————————————————————————————————————————
  group('E2E-03 Perfil', () {
    late Consultora original;

    Future<void> abrirPerfil(WidgetTester tester) async {
      await abrirApp(tester);
      original = injetor<RepositorioConsultora>().atual!;
      addTearDown(
        () => injetor<RepositorioConsultora>().atualizar(
          nome: original.nome,
          whatsapp: original.whatsapp,
          chavePix: original.chavePix,
        ),
      );
      await abrirMenu(tester);
      await tocar(tester, find.text('Ver perfil'));
      await esperarAte(tester, find.text('Meu Perfil'));
    }

    Future<void> salvar(WidgetTester tester) async {
      await tocar(tester, find.text('Salvar Alterações'));
      await esperarAte(
        tester,
        find.text('Meu Perfil'),
        descricao: 'volta ao perfil após salvar',
      );
    }

    testWidgets('mostra os dados e abre por cima (sem a barra)', (
      tester,
    ) async {
      await abrirPerfil(tester);
      expect(find.text(original.nome), findsWidgets);
      expect(find.text('Editar Perfil'), findsOneWidget);
      expect(find.bySemanticsLabel('Produtos'), findsNothing);

      await tocar(tester, find.byTooltip('Voltar'));
      expect(find.bySemanticsLabel('Produtos'), findsWidgets);
    });

    testWidgets('editar o nome grava no banco e atualiza o menu', (
      tester,
    ) async {
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

    testWidgets(
      'chave Pix: CPF inválido é recusado; e-mail é salvo e copiado',
      (tester) async {
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
        expect(find.text('Tipo: E-mail'), findsNothing);
        expect(find.text('e2e@souconsultora.app'), findsOneWidget);

        await tocar(tester, find.byTooltip('Copiar chave Pix'));
        expect(find.text('Chave Pix copiada'), findsOneWidget);
      },
    );

    testWidgets('cancelar a edição não grava', (tester) async {
      await abrirPerfil(tester);
      await tocar(tester, find.text('Editar Perfil'));
      await digitar(tester, 'Nome completo', 'Nome que não deve ficar');
      await tocar(tester, find.text('Cancelar'));

      expect(find.text('Meu Perfil'), findsOneWidget);
      expect(find.text('Nome que não deve ficar'), findsNothing);
    });

    testWidgets(
      'folha da foto oferece câmera e galeria (o fluxo nativo é manual)',
      (tester) async {
        await abrirPerfil(tester);
        await tocar(tester, find.byTooltip('Alterar foto'));
        expect(find.text('Foto do Perfil'), findsOneWidget);
        expect(find.text('Tirar foto'), findsOneWidget);
        expect(find.text('Escolher da galeria'), findsOneWidget);
        await tocar(tester, find.byTooltip('Fechar'));
      },
    );

    testWidgets(
      'sair pede confirmação (o teste cancela para manter a sessão)',
      (tester) async {
        await abrirPerfil(tester);
        await tocar(tester, find.text('Mais opções'));
        await tocar(tester, find.text('Sair da Conta'));
        expect(find.text('Sair da conta?'), findsOneWidget);

        await tocar(tester, find.text('Cancelar'));
        expect(find.text('Meu Perfil'), findsOneWidget);
      },
    );
  }, skip: pularGrupo('E2E-03'));

  // ————————————————————————————————————————————————————————————————
  // E2E-04 · Clientes
  // Apagar cliente não existe no app: o cenário reaproveita uma única
  // cliente "E2E Cliente" (cria só na primeira vez) e restaura o que editar.
  // ————————————————————————————————————————————————————————————————
  group('E2E-04 Clientes', () {
    const nomeE2e = 'E2E Cliente';

    // Só o card da lista: `find.text` também acharia o texto digitado na busca.
    final cardE2e = find.descendant(
      of: find.byType(CartaoListaApp),
      matching: find.text(nomeE2e),
    );

    Future<void> abrirClientes(WidgetTester tester) async {
      await abrirApp(tester);
      await tester.tap(find.bySemanticsLabel('Clientes').last);
      await tester.pumpAndSettle();
      // Lista com clientes mostra o contador; conta sem clientes mostra o estado vazio.
      final listaOuVazia = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'Nenhuma cliente ainda' ||
                RegExp(r'^\d+ clientes?$').hasMatch(w.data ?? '')),
      );
      await esperarAte(
        tester,
        listaOuVazia,
        descricao: 'lista de clientes (ou vazia)',
      );
    }

    /// Cadastra a cliente E2E (com CEP real) se ainda não existir.
    Future<void> garantirClienteE2e(WidgetTester tester) async {
      final vazia = find.text('Nenhuma cliente ainda').evaluate().isNotEmpty;
      if (!vazia) {
        await digitar(tester, 'Buscar cliente', nomeE2e);
        if (cardE2e.evaluate().isNotEmpty) return;
      }

      await tocar(
        tester,
        find.text(vazia ? 'Cadastrar cliente' : 'Novo cliente'),
      );
      await digitar(tester, 'Nome completo da cliente', nomeE2e);
      await digitar(tester, 'WhatsApp com DDD', '11999990001');
      await tocar(tester, find.text('Continuar'));
      await digitar(tester, 'CEP', '01001000');
      await esperarAte(
        tester,
        find.text('Praça da Sé'),
        descricao: 'endereço pelo ViaCEP',
      );
      await digitar(tester, 'Número', '10');
      await tocar(tester, find.text('Salvar Cliente'));
      await esperarAte(tester, cardE2e, descricao: 'cliente nova na lista');
    }

    testWidgets(
      'cadastra (1ª vez), busca sem diferenciar maiúsculas e abre detalhes e dados por cima',
      (tester) async {
        await abrirClientes(tester);
        await garantirClienteE2e(tester);

        await digitar(tester, 'Buscar cliente', 'e2e cliente');
        expect(cardE2e, findsOneWidget);

        await tocar(tester, cardE2e);
        await esperarAte(tester, find.text('Dados Cadastrais'));
        expect(
          find.bySemanticsLabel('Início'),
          findsNothing,
          reason: 'detalhe abre sem a barra',
        );

        await tocar(tester, find.text('Dados Cadastrais'));
        await esperarAte(tester, find.text('(11) 99999-0001'));
        await mostrar(tester, find.text('Praça da Sé, 10'));
        expect(find.text('Praça da Sé, 10'), findsOneWidget);
      },
    );

    testWidgets('editar as observações grava no banco e restaura no fim', (
      tester,
    ) async {
      await abrirClientes(tester);
      await garantirClienteE2e(tester);
      final repositorio = injetor<RepositorioClientes>();
      final id = repositorio.lista!.firstWhere((c) => c.nome == nomeE2e).id;
      final original =
          (await repositorio.buscarCliente(id) as Sucesso<Cliente?>).valor!;
      addTearDown(
        () => repositorio.salvar(
          id: id,
          nome: original.nome,
          whatsapp: original.whatsapp,
          dataNascimento: original.dataNascimento,
          observacoes: original.observacoes,
          endereco: original.endereco,
        ),
      );

      final nota =
          'Prefere florais E2E ${DateTime.now().millisecondsSinceEpoch}';
      await tocar(tester, cardE2e);
      await esperarAte(tester, find.text('Dados Cadastrais'));
      await tocar(tester, find.text('Dados Cadastrais'));
      await esperarAte(tester, find.text('Editar'));
      await tocar(tester, find.text('Editar'));
      await esperarAte(tester, find.text('Editar Cliente'));
      await digitar(tester, 'Observações ou preferências', nota);
      await tocar(tester, find.text('Continuar'));
      await tocar(tester, find.text('Salvar Cliente'));
      await esperarAte(tester, find.text('Dados Cadastrais'));
      await mostrar(tester, find.text(nota));
      expect(find.text(nota), findsOneWidget);

      // Relê do banco: confirma que gravou de verdade.
      final relido =
          (await repositorio.buscarCliente(id) as Sucesso<Cliente?>).valor!;
      expect(relido.observacoes, nota);
    });
  }, skip: pularGrupo('E2E-04'));

  // ————————————————————————————————————————————————————————————————
  // E2E-05 · Fornecedores
  // Não existe exclusão de fornecedor: o cenário reaproveita um único
  // fornecedor "E2E Fornecedor" (cria só na primeira vez) e sempre o
  // devolve a ativo no fim.
  // ————————————————————————————————————————————————————————————————
  group('E2E-05 Fornecedores', () {
    const nomeE2e = 'E2E Fornecedor';

    final cardE2e = find.descendant(
      of: find.byType(CartaoListaApp),
      matching: find.text(nomeE2e),
    );

    Future<void> abrirFornecedores(WidgetTester tester) async {
      await abrirApp(tester);
      await abrirMenu(tester);
      await tocarNoMenu(tester, 'Fornecedores');
      final listaOuVazia = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'Nenhum fornecedor ainda' ||
                RegExp(r'^\d+ fornecedor').hasMatch(w.data ?? '')),
      );
      await esperarAte(
        tester,
        listaOuVazia,
        descricao: 'lista de fornecedores (ou vazia)',
      );
    }

    Future<void> buscar(WidgetTester tester, String texto) async {
      await tester.enterText(find.byType(TextField).first, texto);
      await tester.pumpAndSettle();
    }

    /// O fornecedor E2E pode ter sido criado por outro grupo (E2E-06):
    /// garante o telefone e o ramo que estes cenários conferem.
    Future<void> completarFornecedorE2e(WidgetTester tester) async {
      final repositorio = injetor<RepositorioFornecedores>();
      final atual = repositorio.lista!.firstWhere((f) => f.nome == nomeE2e);
      if (atual.telefone == fornecedorE2e.telefone) return;
      await repositorio.salvar(fornecedorE2e, id: atual.id);
      await tester.pumpAndSettle();
    }

    /// Cadastra o fornecedor E2E se ainda não existir.
    Future<void> garantirFornecedorE2e(WidgetTester tester) async {
      final vazia = find.text('Nenhum fornecedor ainda').evaluate().isNotEmpty;
      if (!vazia) {
        await buscar(tester, nomeE2e);
        if (cardE2e.evaluate().isNotEmpty) {
          await completarFornecedorE2e(tester);
          return;
        }
      }

      await tocar(
        tester,
        find.text(vazia ? 'Cadastrar fornecedor' : 'Fornecedor'),
      );
      await digitar(tester, 'Nome da marca', nomeE2e);
      await digitar(tester, 'Ramo', 'Teste automatizado');
      await digitar(tester, 'Telefone', '11999990002');
      await tocar(tester, find.text('Salvar'));
      await esperarAte(tester, cardE2e, descricao: 'fornecedor novo na lista');
    }

    testWidgets(
      'cadastra (1ª vez), busca sem diferenciar maiúsculas e abre os detalhes por cima',
      (tester) async {
        await abrirFornecedores(tester);
        await garantirFornecedorE2e(tester);

        await buscar(tester, 'e2e fornecedor');
        expect(cardE2e, findsOneWidget);

        await tocar(tester, cardE2e);
        await esperarAte(tester, find.text('Detalhes do Fornecedor'));
        expect(
          find.bySemanticsLabel('Início'),
          findsNothing,
          reason: 'detalhe abre sem a barra',
        );
        await mostrar(tester, find.text('(11) 99999-0002'));
        expect(find.text('(11) 99999-0002'), findsOneWidget);
        expect(find.textContaining('Excluir'), findsNothing);
      },
    );

    testWidgets('colocar em espera grava no banco e volta a ativo no fim', (
      tester,
    ) async {
      await abrirFornecedores(tester);
      await garantirFornecedorE2e(tester);
      final repositorio = injetor<RepositorioFornecedores>();
      final original = repositorio.lista!.firstWhere((f) => f.nome == nomeE2e);
      addTearDown(
        () => repositorio.salvar(
          Fornecedor(
            nome: original.nome,
            ramo: original.ramo,
            contato: original.contato,
            telefone: original.telefone,
            observacoes: original.observacoes,
          ),
          id: original.id,
        ),
      );

      await tocar(tester, cardE2e);
      await esperarAte(tester, find.text('Editar Fornecedor'));
      await tocar(tester, find.text('Editar Fornecedor'));
      await esperarAte(tester, find.text('Salvar'));
      await mostrar(tester, find.text('Em espera'));
      await tocar(tester, find.text('Em espera'));
      await tocar(tester, find.text('Salvar'));
      await esperarAte(tester, find.text('Detalhes do Fornecedor'));
      // O selo da tela depende dos boletos da marca (vence hoje/atrasado
      // tem prioridade sobre "Em espera"); o que vale aqui é o banco.

      // Relê do banco: confirma que gravou de verdade.
      final relido = await repositorio.buscarResumo(original.id);
      expect((relido as Sucesso).valor!.emEspera, isTrue);
    });
  }, skip: pularGrupo('E2E-05'));

  // ————————————————————————————————————————————————————————————————
  // E2E-06 · Produtos
  // ————————————————————————————————————————————————————————————————
  group('E2E-06 Produtos', () {
    const nomeE2e = 'E2E Produto';
    const marcaE2e = 'E2E Fornecedor';

    final cardE2e = find.descendant(
      of: find.byType(CartaoListaApp),
      matching: find.text(nomeE2e),
    );

    Future<void> abrirProdutos(WidgetTester tester) async {
      await abrirApp(tester);
      await tester.tap(find.bySemanticsLabel('Produtos').last);
      await tester.pumpAndSettle();
      final listaOuVazia = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'Nenhum produto ainda' ||
                RegExp(r'^\d+ produtos?$').hasMatch(w.data ?? '')),
      );
      await esperarAte(
        tester,
        listaOuVazia,
        descricao: 'lista de produtos (ou vazia)',
      );
    }

    Future<void> buscar(WidgetTester tester, String texto) async {
      await tester.enterText(find.byType(TextField).first, texto);
      await tester.pumpAndSettle();
    }

    /// A marca E2E é criada pelo E2E-05; se ainda não existir, grava direto.
    Future<void> garantirMarcaE2e() async {
      final fornecedores = injetor<RepositorioFornecedores>();
      final lista = await fornecedores.carregar();
      final existe = (lista as Sucesso).valor.any((f) => f.nome == marcaE2e);
      if (!existe) await fornecedores.salvar(fornecedorE2e);
    }

    Future<void> escolher(
      WidgetTester tester,
      String campo,
      String opcao,
    ) async {
      await tocar(tester, find.text(campo));
      await tocar(tester, find.text(opcao).last);
    }

    /// Cadastra o produto E2E (sem foto) se ainda não existir.
    Future<void> garantirProdutoE2e(WidgetTester tester) async {
      final vazia = find.text('Nenhum produto ainda').evaluate().isNotEmpty;
      if (!vazia) {
        await buscar(tester, nomeE2e);
        if (cardE2e.evaluate().isNotEmpty) return;
      }

      if (vazia) {
        await tocar(tester, find.text('Cadastrar produto'));
      } else {
        await tocar(tester, find.text('Opções'));
        await tocar(tester, find.text('Novo produto'));
      }
      await esperarAte(tester, find.text('Continuar'));
      await digitar(tester, 'Nome do produto', nomeE2e);
      await escolher(tester, 'Escolha a marca', marcaE2e);
      await escolher(tester, 'Escolha a categoria', 'Perfumaria');
      await digitar(tester, 'Código', 'E2E-001');
      await tocar(tester, find.text('Continuar'));
      await esperarAte(tester, find.text('Salvar Produto'));
      await digitar(tester, 'Preço de venda', '9990');
      await tocar(tester, find.text('Salvar Produto'));
      await esperarAte(tester, cardE2e, descricao: 'produto novo na lista');
    }

    testWidgets(
      'cadastra (1ª vez) em 2 passos, aparece Esgotado, busca pelo código e abre os detalhes',
      (tester) async {
        await abrirProdutos(tester);
        await garantirMarcaE2e();
        await garantirProdutoE2e(tester);

        await buscar(tester, 'e2e-001');
        expect(cardE2e, findsOneWidget);
        expect(find.text('Esgotado'), findsWidgets);

        await tocar(tester, cardE2e);
        await esperarAte(tester, find.text('Detalhes do Produto'));
        expect(
          find.bySemanticsLabel('Início'),
          findsNothing,
          reason: 'detalhe abre sem a barra',
        );
        expect(find.text(marcaE2e.toUpperCase()), findsOneWidget);
        expect(find.textContaining('Excluir'), findsNothing);
      },
    );

    testWidgets('editar o preço grava no banco e volta ao original no fim', (
      tester,
    ) async {
      await abrirProdutos(tester);
      await garantirMarcaE2e();
      await garantirProdutoE2e(tester);
      final repositorio = injetor<RepositorioProdutos>();
      final original = repositorio.lista!.firstWhere((p) => p.nome == nomeE2e);
      addTearDown(
        () => repositorio.salvar(original.paraProduto(), id: original.id),
      );

      await buscar(tester, nomeE2e);
      await tocar(tester, cardE2e);
      await esperarAte(tester, find.text('Editar Produto'));
      await tocar(tester, find.text('Editar Produto'));
      await esperarAte(tester, find.text('Continuar'));
      await tocar(tester, find.text('Continuar'));
      await esperarAte(tester, find.text('Salvar Produto'));
      final novoPreco = original.precoVenda + 1000;
      await digitar(
        tester,
        'Preço de venda',
        FormatadorMoeda.formatarSemSimbolo(novoPreco),
      );
      await tocar(tester, find.text('Salvar Produto'));
      await esperarAte(tester, find.text('Detalhes do Produto'));

      // Relê do banco: confirma que gravou de verdade.
      final relido = await repositorio.buscarResumo(original.id);
      expect((relido as Sucesso).valor!.precoVenda, novoPreco);
    });
  }, skip: pularGrupo('E2E-06'));

  // ————————————————————————————————————————————————————————————————
  // E2E-07 · Estoque
  // ————————————————————————————————————————————————————————————————
  group('E2E-07 Estoque', () {
    const nomeProduto = 'E2E Produto';

    final cardProduto = find.descendant(
      of: find.byType(CartaoListaApp),
      matching: find.text(nomeProduto),
    );

    testWidgets(
      'lança 2 unidades pela aba Estoque, grava o lote no banco e apaga no fim',
      (tester) async {
        await abrirApp(tester);
        await tester.tap(find.bySemanticsLabel('Produtos').last);
        await tester.pumpAndSettle();
        await esperarAte(
          tester,
          find.textContaining(RegExp(r'^\d+ produtos?$')),
          descricao: 'lista de produtos',
        );
        await tester.enterText(find.byType(TextField).first, nomeProduto);
        await tester.pumpAndSettle();
        if (cardProduto.evaluate().isEmpty) {
          fail('Rode antes o E2E-06: ele cria o produto "$nomeProduto".');
        }

        final produtos = injetor<RepositorioProdutos>();
        final estoque = injetor<RepositorioEstoque>();
        final produto = produtos.lista!.firstWhere(
          (p) => p.nome == nomeProduto,
        );
        final antes = produto.qtdDisponivel;
        final lotesAntes = await estoque.lotes(produto.id);
        final idsAntes = {
          for (final lote in (lotesAntes as Sucesso).valor) lote.id,
        };
        // Apaga só o lote criado por este cenário (o saldo volta ao original).
        addTearDown(() async {
          final depois = await estoque.lotes(produto.id);
          for (final lote in (depois as Sucesso).valor) {
            if (!idsAntes.contains(lote.id)) await estoque.apagarLote(lote.id);
          }
        });

        await tocar(tester, cardProduto);
        await esperarAte(tester, find.text('Detalhes do Produto'));
        await tocar(tester, find.text('Estoque $antes'));
        // Sem lotes o botão fica no vazio da aba ("Lançar estoque"); com lotes, no rodapé.
        final lancar = find.text('Lançar estoque').evaluate().isNotEmpty
            ? find.text('Lançar estoque')
            : find.text('Lançar Estoque');
        await tocar(tester, lancar);
        await esperarAte(tester, find.text('Adicionar Produto ao Estoque'));

        await tocar(tester, find.byTooltip('Aumentar'));
        await tester.enterText(
          find.descendant(
            of: find.byType(CampoMoedaApp),
            matching: find.byType(EditableText),
          ),
          '5000',
        );
        await tester.pumpAndSettle();
        await mostrar(tester, find.text('Adicionar à Compra'));
        await tocar(tester, find.text('Adicionar à Compra'));
        await esperarAte(tester, find.text('1 item'));
        await tocar(tester, find.text('Salvar lançamento'));
        await esperarAte(tester, find.text('Detalhes do Produto'));
        await esperarAte(tester, find.text('Pronta entrega'));

        // Relê do banco: confirma que o lote foi gravado de verdade.
        final relidos = await estoque.lotes(produto.id);
        final novos = [
          for (final lote in (relidos as Sucesso).valor)
            if (!idsAntes.contains(lote.id)) lote,
        ];
        expect(novos.single.quantidade, 2);
        expect(novos.single.custoUnitario, 5000);
        expect(novos.single.fornecedorNome, fornecedorE2e.nome);
        expect(produtos.resumoEmCache(produto.id)!.qtdDisponivel, antes + 2);
      },
    );
  }, skip: pularGrupo('E2E-07'));

  // ————————————————————————————————————————————————————————————————
  // E2E-08 · Serviços
  // ————————————————————————————————————————————————————————————————
  group('E2E-08 Serviços', () {
    const nomeE2e = 'E2E Serviço';

    final cardE2e = find.descendant(
      of: find.byType(CartaoListaApp),
      matching: find.text(nomeE2e),
    );

    Future<void> abrirServicos(WidgetTester tester) async {
      await abrirApp(tester);
      await abrirMenu(tester);
      await tocarNoMenu(tester, 'Serviços');
      final listaOuVazia = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'Nenhum serviço ainda' ||
                RegExp(r'^\d+ serviços?$').hasMatch(w.data ?? '')),
      );
      await esperarAte(tester, listaOuVazia, descricao: 'lista de serviços');
    }

    /// Cadastra o serviço E2E (sem foto) se ainda não existir.
    Future<void> garantirServicoE2e(WidgetTester tester) async {
      final vazia = find.text('Nenhum serviço ainda').evaluate().isNotEmpty;
      if (!vazia) {
        await tester.enterText(find.byType(TextField).first, nomeE2e);
        await tester.pumpAndSettle();
        if (cardE2e.evaluate().isNotEmpty) return;
      }
      await tocar(
        tester,
        find.text(vazia ? 'Cadastrar serviço' : 'Novo serviço'),
      );
      await esperarAte(tester, find.text('Salvar Serviço'));
      await digitar(tester, 'Nome do serviço', nomeE2e);
      await tocar(tester, find.text('Escolha a categoria'));
      await tocar(tester, find.text('Unhas').last);
      await digitar(tester, 'Preço de venda', '6500');
      await digitar(tester, 'Custo de materiais', '1500');
      await tocar(tester, find.text('Salvar Serviço'));
      await esperarAte(tester, cardE2e, descricao: 'serviço novo na lista');
    }

    testWidgets(
      'cadastra (1ª vez), abre detalhes e edita o preço (restaura no fim)',
      (tester) async {
        await abrirServicos(tester);
        await garantirServicoE2e(tester);
        final repositorio = injetor<RepositorioServicos>();
        final original = repositorio.lista!.firstWhere(
          (s) => s.nome == nomeE2e,
        );
        addTearDown(
          () => repositorio.salvar(original.paraServico(), id: original.id),
        );

        await tocar(tester, cardE2e);
        await esperarAte(tester, find.text('Detalhes do Serviço'));
        expect(find.text('Retorno estimado'), findsOneWidget);
        expect(find.textContaining('Excluir'), findsNothing);

        await tocar(tester, find.text('Editar Serviço'));
        await esperarAte(tester, find.text('Salvar Serviço'));
        final novoPreco = original.precoCobrado + 1000;
        await digitar(
          tester,
          'Preço de venda',
          FormatadorMoeda.formatarSemSimbolo(novoPreco),
        );
        await tocar(tester, find.text('Salvar Serviço'));
        await esperarAte(tester, find.text('Detalhes do Serviço'));

        final relido = await repositorio.buscarResumo(original.id);
        expect((relido as Sucesso).valor!.precoCobrado, novoPreco);
      },
    );
  }, skip: pularGrupo('E2E-08'));

  // ————————————————————————————————————————————————————————————————
  // E2E-09 · Vendas
  // ————————————————————————————————————————————————————————————————
  group('E2E-09 Vendas', () {
    const cliente = 'E2E Cliente';
    const produto = 'E2E Produto';

    Future<void> escolher(
      WidgetTester tester,
      String campo,
      String opcao,
    ) async {
      await tocar(tester, find.text(campo));
      await tocar(tester, find.text(opcao).last);
    }

    testWidgets(
      'registra uma encomenda à vista, confere no banco e cancela pela tela',
      (tester) async {
        await abrirApp(tester);
        final vendas = injetor<RepositorioVendas>();
        final antes = await vendas.carregar();
        final idsAntes = {for (final v in (antes as Sucesso).valor) v.id};
        // Garante a limpeza mesmo se o cenário falhar no meio.
        addTearDown(() async {
          final depois = await vendas.carregar();
          for (final v in (depois as Sucesso).valor) {
            if (!idsAntes.contains(v.id)) await vendas.cancelar(v.id);
          }
        });

        await tester.tap(find.bySemanticsLabel('Vendas').last);
        await tester.pumpAndSettle();
        await esperarAte(
          tester,
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data == 'Nenhuma venda ainda' ||
                    RegExp(r'^\d+ vendas?$').hasMatch(w.data ?? '')),
          ),
          descricao: 'lista de vendas',
        );
        await tocar(
          tester,
          find.text(
            find.text('Nenhuma venda ainda').evaluate().isEmpty
                ? 'Nova venda'
                : 'Registrar venda',
          ),
        );
        await esperarAte(tester, find.text('Adicionar Produto ou Serviço'));

        if (find.text('Escolha a cliente').evaluate().isNotEmpty) {
          await tocar(tester, find.text('Escolha a cliente'));
          if (find.text(cliente).evaluate().isEmpty) {
            fail('Rode antes o E2E-04: ele cria a cliente "$cliente".');
          }
          await tocar(tester, find.text(cliente).last);
        }
        await tocar(tester, find.text('Adicionar Produto ou Serviço'));
        await escolher(tester, 'Escolha o produto', produto);
        await mostrar(tester, find.text('Baixar do estoque'));
        await tocar(tester, find.text('Baixar do estoque'));
        await mostrar(tester, find.text('Salvar'));
        await tocar(tester, find.text('Salvar'));
        await tocar(tester, find.text('Avançar'));
        await esperarAte(tester, find.text('Como a cliente vai pagar?'));
        await mostrar(tester, find.text('Concluir Venda'));
        await tocar(tester, find.text('Concluir Venda'));
        await esperarAte(
          tester,
          find.text('Buscar por cliente, produto ou código...'),
        );

        // Relê do banco: a venda nova existe, com o item como encomenda.
        final depois = await vendas.carregar();
        final nova = (depois as Sucesso).valor.firstWhere(
          (v) => !idsAntes.contains(v.id),
        );
        expect(nova.clienteNome, cliente);
        final detalhe = await vendas.detalhe(nova.id);
        final itens = (detalhe as Sucesso).valor!.itens;
        expect(itens.single.nome, produto);
        expect(itens.single.baixarEstoque, isFalse);

        await tester.enterText(
          find.byType(TextField).first,
          nova.codigo.toString(),
        );
        await tester.pumpAndSettle();
        await tocar(tester, find.text(cliente).first);
        await esperarAte(tester, find.text('Detalhes da Venda'));
        await tocar(tester, find.text('Mais opções'));
        await tocar(tester, find.text('Cancelar Venda'));
        await tocar(tester, find.text('Cancelar venda'));
        // A lista fica vazia (sem busca) se esta era a única venda.
        await esperarAte(
          tester,
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data == 'Nenhuma venda ainda' ||
                    w.data == 'Buscar por cliente, produto ou código...'),
          ),
        );

        final aposCancelar = await vendas.carregar();
        expect(
          (aposCancelar as Sucesso).valor.any((v) => v.id == nova.id),
          isFalse,
        );
      },
    );
  }, skip: pularGrupo('E2E-09'));

  // ————————————————————————————————————————————————————————————————
  // E2E-10 · A receber
  // ————————————————————————————————————————————————————————————————
  group('E2E-10 A receber', () {
    const cliente = 'E2E Cliente';
    const servico = 'E2E Serviço';

    testWidgets(
      'paga parte da 1ª parcela pela tela, confere no banco e o comprovante',
      (tester) async {
        await abrirApp(tester);
        final vendas = injetor<RepositorioVendas>();
        final recebimentos = injetor<RepositorioRecebimentos>();

        // Venda de teste em 2x, criada direto pelo repositório (a tela de
        // nova venda é coberta no E2E-09). Serviço: não mexe no estoque.
        final clientes = await injetor<RepositorioClientes>().carregar();
        final daCliente = (clientes as Sucesso).valor.where(
          (c) => c.nome == cliente,
        );
        if (daCliente.isEmpty) {
          fail('Rode antes o E2E-04: ele cria a cliente "$cliente".');
        }
        final servicos = await injetor<RepositorioServicos>().carregar();
        final doServico = (servicos as Sucesso).valor.where(
          (s) => s.nome == servico,
        );
        if (doServico.isEmpty) {
          fail('Rode antes o E2E-08: ele cria o serviço "$servico".');
        }
        final item = doServico.first;
        final hoje = DateTime.now();
        final primeira = item.precoCobrado ~/ 2;
        final resultado = await vendas.concluir(
          PedidoVenda(
            clienteId: daCliente.first.id,
            dataVenda: hoje,
            itens: [
              ItemPedido(
                tipo: TipoItem.servico,
                catalogoId: item.id,
                nome: item.nome,
                precoUnitario: item.precoCobrado,
                quantidade: 1,
                baixarEstoque: false,
              ),
            ],
            parcelas: [
              // A 1ª vence hoje: aparece no mês atual (filtro padrão).
              ParcelaPlano(valor: primeira, vencimento: hoje),
              ParcelaPlano(
                valor: item.precoCobrado - primeira,
                vencimento: hoje.add(const Duration(days: 30)),
              ),
            ],
          ),
        );
        final idVenda = (resultado as Sucesso<String>).valor;
        // A venda é sempre cancelada, mesmo se o cenário falhar no meio.
        addTearDown(() async {
          final ainda = await vendas.detalhe(idVenda);
          if (ainda case Sucesso(valor: _?)) await vendas.cancelar(idVenda);
        });

        final parcelas = await recebimentos.carregar();
        final parcela = (parcelas as Sucesso).valor.firstWhere(
          (p) => p.vendaId == idVenda && p.numero == 1,
        );
        final parcial = parcela.valor ~/ 2;

        // Lista: busca pela cliente e abre a 1ª parcela desta venda.
        await abrirMenu(tester);
        await tocarNoMenu(tester, 'A Receber');
        await esperarAte(tester, find.text('Recebimentos'));
        await esperarAte(
          tester,
          find.textContaining(RegExp(r'^\d+ parcelas?$')),
          descricao: 'lista de parcelas',
        );
        await tester.enterText(find.byType(TextField).first, cliente);
        await tester.pumpAndSettle();
        final cartao = find.textContaining(
          '${parcela.textoCurto} • ${FormatadorMoeda.formatar(parcela.valor)}',
        );
        await tocar(tester, cartao);
        await esperarAte(tester, find.text('Detalhes da Parcela'));
        await esperarAte(
          tester,
          find.text('Pagar'),
          descricao: 'detalhes carregados',
        );
        await mostrar(tester, find.text('Venda ${parcela.codigoVenda}'));
        expect(find.text('Venda ${parcela.codigoVenda}'), findsOneWidget);

        // Paga metade pela folha.
        await tocar(tester, find.text('Pagar'));
        await esperarAte(tester, find.text('Registrar pagamento'));
        await tester.enterText(
          find.descendant(
            of: find.byType(CampoMoedaApp),
            matching: find.byType(TextField),
          ),
          parcial.toString(),
        );
        await tester.pumpAndSettle();
        await tocar(tester, find.text('Confirmar'));
        await esperarAte(tester, find.text('Pagamento confirmado'));

        // Banco: um pagamento com o valor parcial; saldo = o resto.
        final relido = await recebimentos.detalhe(parcela.id);
        final detalhe = (relido as Sucesso).valor!;
        expect(detalhe.pagamentos.single.valor, parcial);
        expect(detalhe.parcela.saldo, parcela.valor - parcial);

        // Comprovante do pagamento parcial.
        expect(find.text(FormatadorMoeda.formatar(parcial)), findsWidgets);
        expect(find.text(cliente), findsOneWidget);
        expect(find.text('Parcela 1 de 2 • Parcial'), findsOneWidget);
        await mostrar(tester, find.text('Saldo restante da venda'));
        expect(
          find.text(FormatadorMoeda.formatar(item.precoCobrado - parcial)),
          findsWidgets,
        );
        expect(find.text('Compartilhar'), findsOneWidget);

        // Volta aos detalhes (já com o pagamento); a venda é cancelada pelo repositório.
        await voltarDoSistema(tester);
        await esperarAte(
          tester,
          find.text('Pago ${FormatadorMoeda.formatar(parcial)}'),
        );
        // Na parcela, "Mais opções" não cancela a venda: só edita o pagamento,
        // cobra e gera o recibo.
        await tocar(tester, find.text('Mais opções'));
        expect(find.text('Editar pagamento'), findsWidgets);
        expect(find.text('Cancelar Venda'), findsNothing);
        await tocar(tester, find.text('Fechar'));
        await vendas.cancelar(idVenda);

        final aposCancelar = await vendas.detalhe(idVenda);
        expect((aposCancelar as Sucesso).valor, isNull);
      },
    );
  }, skip: pularGrupo('E2E-10'));

  // ————————————————————————————————————————————————————————————————
  // E2E-11 · A pagar
  // ————————————————————————————————————————————————————————————————
  group('E2E-11 A pagar', () {
    const marca = 'E2E Fornecedor';
    const observacao = 'E2E-11 boleto de teste';
    // A lista, com boletos ou vazia.
    final listaDeBoletos = find.byWidgetPredicate(
      (w) =>
          w is Text && (w.data == 'Nenhum boleto ainda' || w.data == 'A pagar'),
    );

    testWidgets(
      'lança boleto pela tela, confere no banco, paga, desfaz e exclui',
      (tester) async {
        await abrirApp(tester);
        final boletos = injetor<RepositorioBoletos>();
        final antes = await boletos.carregar();
        final idsAntes = {for (final b in (antes as Sucesso).valor) b.id};
        // Garante a limpeza mesmo se o cenário falhar no meio.
        addTearDown(() async {
          final depois = await boletos.carregar();
          for (final b in (depois as Sucesso).valor) {
            if (!idsAntes.contains(b.id)) await boletos.excluir(b);
          }
        });

        await abrirMenu(tester);
        await tocarNoMenu(tester, 'A Pagar');
        await esperarAte(tester, listaDeBoletos, descricao: 'lista de boletos');

        // Lançar: passo 1 (marca, valor, vencimento hoje) e passo 2.
        // Sem boletos o botão é o do estado vazio; com boletos, o flutuante.
        await tocar(
          tester,
          find.text('Lançar boleto').evaluate().isNotEmpty
              ? find.text('Lançar boleto')
              : find.byTooltip('Novo boleto'),
        );
        await esperarAte(tester, find.text('Passo 1 de 2: Dados do Boleto'));
        await tocar(tester, find.text('Selecione a marca ou distribuidora'));
        if (find.text(marca).evaluate().isEmpty) {
          fail('Rode antes o E2E-05: ele cria o fornecedor "$marca".');
        }
        await tocar(tester, find.text(marca).last);
        await tester.enterText(
          find.descendant(
            of: find.byType(CampoMoedaApp),
            matching: find.byType(TextField),
          ),
          '12345',
        );
        await tester.pumpAndSettle();
        await tocar(tester, find.byType(CampoDataApp));
        await tocar(tester, find.text('OK'));
        await tocar(tester, find.text('Continuar'));
        await esperarAte(
          tester,
          find.text('Passo 2 de 2: Pagamento e Lembretes'),
        );
        await tester.enterText(find.byType(TextField).last, observacao);
        await tester.pumpAndSettle();
        await tocar(tester, find.text('Salvar Boleto'));
        await esperarAte(tester, find.text('A pagar'));

        // Banco: o boleto novo, em aberto, com o que foi digitado.
        final hoje = DateTime.now();
        final dia = DateTime(hoje.year, hoje.month, hoje.day);
        final depois = await boletos.carregar();
        final novo = (depois as Sucesso).valor.firstWhere(
          (b) => !idsAntes.contains(b.id),
        );
        expect(novo.fornecedorNome, marca);
        expect(novo.valor, 12345);
        expect(novo.vencimento, dia);
        expect(novo.observacoes, observacao);
        expect(novo.pago, isFalse);

        // Detalhes pela busca da observação.
        await tester.enterText(find.byType(TextField).first, 'E2E-11');
        await tester.pumpAndSettle();
        await tocar(tester, find.text(marca).first);
        await esperarAte(tester, find.text('Detalhes do Boleto'));
        await esperarAte(tester, find.text('Confirmar Pagamento'));

        // Pagar com a data de hoje.
        await tocar(tester, find.text('Confirmar Pagamento'));
        await tocar(tester, find.text('Confirmar'));
        await esperarAte(tester, find.text('VALOR PAGO'));
        final pago = await boletos.buscar(novo.id);
        expect((pago as Sucesso).valor!.dataPagamento, dia);

        // Desfazer.
        await esperarSumir(tester, find.text('Pagamento confirmado.'));
        await tocar(tester, find.text('Mais opções'));
        await tocar(tester, find.text('Desfazer Pagamento'));
        await tocar(tester, find.text('Desfazer'));
        await esperarAte(tester, find.text('Confirmar Pagamento'));
        final desfeito = await boletos.buscar(novo.id);
        expect((desfeito as Sucesso).valor!.pago, isFalse);

        // Excluir pela tela.
        await esperarSumir(tester, find.text('Pagamento desfeito.'));
        await tocar(tester, find.text('Mais opções'));
        await tocar(tester, find.text('Excluir Boleto'));
        await tocar(tester, find.text('Excluir boleto'));
        // Volta à lista (vazia se este era o único boleto).
        await esperarSumir(tester, find.text('Detalhes do Boleto'));
        await esperarAte(tester, listaDeBoletos, descricao: 'lista de boletos');
        final excluido = await boletos.buscar(novo.id);
        expect((excluido as Sucesso).valor, isNull);
      },
    );
  }, skip: pularGrupo('E2E-11'));

  // ————————————————————————————————————————————————————————————————
  // E2E-12 · Financeiro
  // ————————————————————————————————————————————————————————————————
  group('E2E-12 Financeiro', () {
    const servico = 'E2E Serviço';
    const fornecedor = 'E2E Fornecedor';
    const valorBoleto = 4321;

    /// Valor de um Sucesso mantendo o tipo (o cast cru vira dynamic).
    T valorDe<T>(Resultado<T> resultado) => (resultado as Sucesso<T>).valor;

    Future<void> abrirFinanceiro(WidgetTester tester) async {
      // Nas telas de dentro (A receber, A pagar) a barra inferior some: volta.
      for (var i = 0; i < 4; i++) {
        if (find.bySemanticsLabel('Financeiro').evaluate().isNotEmpty) break;
        await voltarDoSistema(tester);
      }
      await tester.tap(find.bySemanticsLabel('Financeiro').last);
      await tester.pumpAndSettle();
      await esperarAte(tester, find.text('Categorias do Mês'));
    }

    /// O mesmo cálculo do app, a partir do que o banco devolve agora.
    Future<ResumoFinanceiro> doBanco() async {
      final vendas = await injetor<RepositorioVendas>().carregar();
      final boletos = await injetor<RepositorioBoletos>().carregar();
      return ResumoFinanceiro.calcular(
        vendas: valorDe(vendas),
        boletos: valorDe(boletos),
        periodo: MesAno.de(DateTime.now()),
      );
    }

    testWidgets(
      'uma venda e um boleto do mês entram nos números (e saem no fim)',
      (tester) async {
        await abrirApp(tester);
        final vendas = injetor<RepositorioVendas>();
        final boletos = injetor<RepositorioBoletos>();
        final antes = await doBanco();

        // Dados temporários do mês atual, criados pelo repositório.
        final clientes = await injetor<RepositorioClientes>().carregar();
        final cliente = valorDe(clientes)
            .where((c) => c.nome == 'E2E Cliente')
            .firstOrNull;
        final servicos = await injetor<RepositorioServicos>().carregar();
        final item = valorDe(servicos)
            .where((s) => s.nome == servico)
            .firstOrNull;
        final marcas = await injetor<RepositorioFornecedores>().carregar();
        final marca = valorDe(marcas)
            .where((f) => f.nome == fornecedor)
            .firstOrNull;
        if (cliente == null || item == null || marca == null) {
          fail(
            'Rode antes o E2E-04, o E2E-05 e o E2E-08 (cliente, '
            'fornecedor e serviço de teste).',
          );
        }
        final hoje = DateTime.now();
        final venda = await vendas.concluir(
          PedidoVenda(
            clienteId: cliente.id,
            dataVenda: hoje,
            itens: [
              ItemPedido(
                tipo: TipoItem.servico,
                catalogoId: item.id,
                nome: item.nome,
                precoUnitario: item.precoCobrado,
                quantidade: 1,
                baixarEstoque: false,
              ),
            ],
            parcelas: [
              ParcelaPlano(valor: item.precoCobrado, vencimento: hoje),
            ],
          ),
        );
        final idVenda = (venda as Sucesso<String>).valor;
        addTearDown(() => vendas.cancelar(idVenda));
        final boleto = await boletos.salvar(
          PedidoBoleto(
            fornecedorId: marca.id,
            valor: valorBoleto,
            vencimento: hoje,
            observacoes: 'E2E-12 boleto temporário',
          ),
        );
        final idBoleto = (boleto as Sucesso<String>).valor;
        addTearDown(() async {
          final ainda = await boletos.buscar(idBoleto);
          if (ainda case Sucesso(valor: final b?)) await boletos.excluir(b);
        });

        final esperado = await doBanco();
        expect(
          esperado.faturamentoDoMes,
          antes.faturamentoDoMes + item.precoCobrado,
        );
        expect(esperado.despesasDoMes, antes.despesasDoMes + valorBoleto);

        await abrirFinanceiro(tester);
        expect(find.textContaining('(Mês atual)'), findsOneWidget);
        expect(
          find.text(
            FormatadorMoeda.formatarSemCentavos(esperado.totalAcumulado),
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Faturamento no mês: '
            '${FormatadorMoeda.formatar(esperado.faturamentoDoMes)}',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Despesas no mês: '
            '${FormatadorMoeda.formatar(esperado.despesasDoMes)}',
            findRichText: true,
          ),
          findsOneWidget,
        );

        // Os atalhos abrem os módulos.
        await tocar(tester, find.text('A Receber'));
        await esperarAte(tester, find.text('Recebimentos'));
        await abrirFinanceiro(tester);
        await tocar(tester, find.text('A Pagar'));
        await esperarAte(tester, find.text('A pagar'));
      },
    );
  }, skip: pularGrupo('E2E-12'));

  // ————————————————————————————————————————————————————————————————
  // E2E-13 · Início
  // ————————————————————————————————————————————————————————————————
  group('E2E-13 Início', () {
    const valorBoleto = 8425;

    /// Valor de um Sucesso mantendo o tipo (o cast cru vira dynamic).
    T valorDe<T>(Resultado<T> resultado) => (resultado as Sucesso<T>).valor;

    /// O mesmo cálculo do app, a partir do que o banco devolve agora.
    Future<ResumoInicio> doBanco() async {
      final inicio = injetor<RepositorioInicio>();
      final (vendas, parcelas, boletos, pagamentos, lembretes) = await (
        injetor<RepositorioVendas>().carregar(),
        injetor<RepositorioRecebimentos>().carregar(),
        injetor<RepositorioBoletos>().carregar(),
        inicio.pagamentos(),
        inicio.lembretes(),
      ).wait;
      return ResumoInicio.calcular(
        vendas: valorDe(vendas),
        parcelas: valorDe(parcelas),
        boletos: valorDe(boletos),
        pagamentos: valorDe(pagamentos),
        lembretes: valorDe(lembretes),
        hoje: DateTime.now(),
      );
    }

    testWidgets(
      'venda atrasada e boleto de amanhã aparecem nos números e alertas',
      (tester) async {
        await abrirApp(tester);
        final vendas = injetor<RepositorioVendas>();
        final boletos = injetor<RepositorioBoletos>();
        final antes = await doBanco();

        final cliente = valorDe(await injetor<RepositorioClientes>().carregar())
            .where((c) => c.nome == 'E2E Cliente')
            .firstOrNull;
        final item = valorDe(await injetor<RepositorioServicos>().carregar())
            .where((s) => s.nome == 'E2E Serviço')
            .firstOrNull;
        final marca = valorDe(
          await injetor<RepositorioFornecedores>().carregar(),
        ).where((f) => f.nome == 'E2E Fornecedor').firstOrNull;
        if (cliente == null || item == null || marca == null) {
          fail(
            'Rode antes o E2E-04, o E2E-05 e o E2E-08 (cliente, '
            'fornecedor e serviço de teste).',
          );
        }

        // Venda de hoje com a parcela vencida há 3 dias (atrasada) e um
        // boleto que vence amanhã — temporários.
        final hoje = DateTime.now();
        final venda = await vendas.concluir(
          PedidoVenda(
            clienteId: cliente.id,
            dataVenda: hoje,
            itens: [
              ItemPedido(
                tipo: TipoItem.servico,
                catalogoId: item.id,
                nome: item.nome,
                precoUnitario: item.precoCobrado,
                quantidade: 1,
                baixarEstoque: false,
              ),
            ],
            parcelas: [
              ParcelaPlano(
                valor: item.precoCobrado,
                vencimento: DateTime(hoje.year, hoje.month, hoje.day - 3),
              ),
            ],
          ),
        );
        final idVenda = valorDe(venda);
        addTearDown(() => vendas.cancelar(idVenda));
        final boleto = await boletos.salvar(
          PedidoBoleto(
            fornecedorId: marca.id,
            valor: valorBoleto,
            vencimento: DateTime(hoje.year, hoje.month, hoje.day + 1),
            observacoes: 'E2E-13 boleto temporário',
          ),
        );
        final idBoleto = valorDe(boleto);
        addTearDown(() async {
          final ainda = await boletos.buscar(idBoleto);
          if (ainda case Sucesso(valor: final b?)) await boletos.excluir(b);
        });

        // Banco: os números sobem exatamente pelo que foi criado.
        final esperado = await doBanco();
        expect(esperado.vendidoNoMes, antes.vendidoNoMes + item.precoCobrado);
        expect(esperado.qtdVendasNoMes, antes.qtdVendasNoMes + 1);
        expect(
          esperado.atrasadas!.total,
          (antes.atrasadas?.total ?? 0) + item.precoCobrado,
        );
        if (antes.alertasBoletos.length < ResumoInicio.maxAlertasBoletos) {
          expect(
            esperado.alertasBoletos.map((a) => a.boleto.id),
            contains(idBoleto),
          );
        }

        // Tela: o Início recalcula sozinho (assina vendas e boletos).
        await tester.tap(find.bySemanticsLabel('Início').last);
        await tester.pumpAndSettle();
        await esperarAte(
          tester,
          find.text(FormatadorMoeda.formatar(esperado.vendidoNoMes)),
          descricao: 'Vendido no mês atualizado',
        );
        expect(find.text('VENCE AMANHÃ'), findsWidgets);
        expect(find.text('E2E Fornecedor'), findsWidgets);
        final atrasadas = esperado.atrasadas!;
        expect(
          find.text(
            atrasadas.qtdClientes == 1
                ? '1 CLIENTE'
                : '${atrasadas.qtdClientes} CLIENTES',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Total ${FormatadorMoeda.formatar(atrasadas.total)}'),
          findsOneWidget,
        );

        // Print do Início com os alertas (build/prints_e2e/e2e13-inicio.png).
        if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
        await tester.pumpAndSettle();
        await binding.takeScreenshot('e2e13-inicio');

        // Cobrar → A receber em Atrasado, todos os meses.
        await tocar(tester, find.text('Cobrar'));
        await esperarAte(tester, find.text('Recebimentos'));
        await esperarAte(tester, find.textContaining('Atrasado ('));
        expect(find.text('Todos os meses'), findsOneWidget);
      },
    );
  }, skip: pularGrupo('E2E-13'));
}
