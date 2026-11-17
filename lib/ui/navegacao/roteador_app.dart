// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/ui/modules/cadastro/cadastro_screen.dart';
import 'package:sou_consultora/ui/modules/clientes/dados/clientes_dados_screen.dart';
import 'package:sou_consultora/ui/modules/clientes/detalhes/clientes_detalhes_screen.dart';
import 'package:sou_consultora/ui/modules/clientes/formulario/clientes_formulario_screen.dart';
import 'package:sou_consultora/ui/modules/clientes/lista/clientes_lista_screen.dart';
import 'package:sou_consultora/ui/modules/fornecedores/detalhes/fornecedores_detalhes_screen.dart';
import 'package:sou_consultora/ui/modules/fornecedores/formulario/fornecedores_formulario_screen.dart';
import 'package:sou_consultora/ui/modules/fornecedores/lista/fornecedores_lista_screen.dart';
import 'package:sou_consultora/ui/modules/login/acesso_login_screen.dart';
import 'package:sou_consultora/ui/modules/produtos/detalhes/produtos_detalhes_screen.dart';
import 'package:sou_consultora/ui/modules/produtos/formulario/produtos_formulario_screen.dart';
import 'package:sou_consultora/ui/modules/produtos/lancar_estoque/lancar_estoque_screen.dart';
import 'package:sou_consultora/ui/modules/produtos/lista/produtos_lista_screen.dart';
import 'package:sou_consultora/ui/modules/perfil/editar/editar_perfil_screen.dart';
import 'package:sou_consultora/ui/modules/perfil/meu_perfil/meu_perfil_screen.dart';
import 'package:sou_consultora/ui/navegacao/carregando_screen.dart';
import 'package:sou_consultora/ui/navegacao/casca/casca_principal_screen.dart';
import 'package:sou_consultora/ui/navegacao/em_construcao_screen.dart';
import 'package:sou_consultora/ui/navegacao/notificador_acesso.dart';
import 'package:sou_consultora/ui/navegacao/regras_de_acesso.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';

/// Roteador único do app.
///
/// - Telas principais ficam dentro do [ShellRoute] (com barra e menu).
/// - Telas de detalhe/formulário devem usar `parentNavigatorKey: chaveRaiz`
///   para abrir por cima, sem a barra.
/// - O redirecionamento reage a cada mudança de acesso ([NotificadorAcesso]).
abstract final class RoteadorApp {
  static final chaveRaiz = GlobalKey<NavigatorState>(debugLabel: 'raiz');

  static GoRouter criar({required NotificadorAcesso acesso}) {
    return GoRouter(
      navigatorKey: chaveRaiz,
      initialLocation: RotasApp.inicio,
      refreshListenable: acesso,
      redirect: (_, estado) => destinoPermitido(
        estado: acesso.estado,
        destino: estado.matchedLocation,
      ),
      routes: [
        GoRoute(path: '/', redirect: (_, _) => RotasApp.inicio),
        GoRoute(
          path: RotasApp.login,
          builder: (_, _) => const AcessoLoginScreen(),
        ),
        GoRoute(
          path: RotasApp.carregando,
          builder: (_, _) => CarregandoScreen(acesso: acesso),
        ),
        GoRoute(
          path: RotasApp.cadastro,
          builder: (_, _) => const CadastroScreen(),
        ),
        GoRoute(
          path: RotasApp.perfil,
          parentNavigatorKey: chaveRaiz,
          builder: (_, _) => const MeuPerfilScreen(),
          routes: [
            GoRoute(
              path: 'editar',
              parentNavigatorKey: chaveRaiz,
              builder: (_, _) => const EditarPerfilScreen(),
            ),
          ],
        ),
        ShellRoute(
          builder: (_, estado, filho) => CascaPrincipalScreen(
            caminhoAtual: estado.matchedLocation,
            filho: filho,
          ),
          routes: [
            for (final modulo in RotasApp.modulos)
              switch (modulo.rota) {
                RotasApp.clientes => _rotaClientes(),
                RotasApp.fornecedores => _rotaFornecedores(),
                RotasApp.produtos => _rotaProdutos(),
                _ => _rotaEmConstrucao(modulo),
              },
          ],
        ),
        // Construída na fase de Vendas.
        GoRoute(
          path: '/vendas/nova',
          parentNavigatorKey: chaveRaiz,
          builder: (_, _) =>
              const EmConstrucaoScreen.porCima(titulo: 'Nova Venda'),
        ),
      ],
    );
  }

  /// Lista na casca; novo, detalhes, dados e edição abrem por cima (sem a barra).
  static GoRoute _rotaClientes() {
    return GoRoute(
      path: RotasApp.clientes,
      pageBuilder: (_, estado) => NoTransitionPage(
        key: estado.pageKey,
        child: const ClientesListaScreen(),
      ),
      routes: [
        GoRoute(
          path: 'novo',
          parentNavigatorKey: chaveRaiz,
          builder: (_, _) => const ClientesFormularioScreen(),
        ),
        GoRoute(
          path: ':id',
          parentNavigatorKey: chaveRaiz,
          builder: (_, estado) =>
              ClientesDetalhesScreen(idCliente: estado.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'dados',
              parentNavigatorKey: chaveRaiz,
              builder: (_, estado) =>
                  ClientesDadosScreen(idCliente: estado.pathParameters['id']!),
            ),
            GoRoute(
              path: 'editar',
              parentNavigatorKey: chaveRaiz,
              builder: (_, estado) => ClientesFormularioScreen(
                idCliente: estado.pathParameters['id'],
              ),
            ),
            // Construída na fase de Vendas.
            GoRoute(
              path: 'compras',
              parentNavigatorKey: chaveRaiz,
              builder: (_, _) => const EmConstrucaoScreen.porCima(
                titulo: 'Compras da Cliente',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Lista na casca; novo, detalhes e edição abrem por cima (sem a barra).
  static GoRoute _rotaFornecedores() {
    return GoRoute(
      path: RotasApp.fornecedores,
      pageBuilder: (_, estado) => NoTransitionPage(
        key: estado.pageKey,
        child: const FornecedoresListaScreen(),
      ),
      routes: [
        GoRoute(
          path: 'novo',
          parentNavigatorKey: chaveRaiz,
          builder: (_, _) => const FornecedoresFormularioScreen(),
        ),
        GoRoute(
          path: ':id',
          parentNavigatorKey: chaveRaiz,
          builder: (_, estado) => FornecedoresDetalhesScreen(
            idFornecedor: estado.pathParameters['id']!,
          ),
          routes: [
            GoRoute(
              path: 'editar',
              parentNavigatorKey: chaveRaiz,
              builder: (_, estado) => FornecedoresFormularioScreen(
                idFornecedor: estado.pathParameters['id'],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Lista na casca; novo, detalhes e edição abrem por cima (sem a barra).
  static GoRoute _rotaProdutos() {
    return GoRoute(
      path: RotasApp.produtos,
      pageBuilder: (_, estado) => NoTransitionPage(
        key: estado.pageKey,
        child: const ProdutosListaScreen(),
      ),
      routes: [
        GoRoute(
          path: 'novo',
          parentNavigatorKey: chaveRaiz,
          builder: (_, _) => const ProdutosFormularioScreen(),
        ),
        // Antes de ':id', para não ser lida como o id de um produto.
        GoRoute(
          path: 'lancar-estoque',
          parentNavigatorKey: chaveRaiz,
          builder: (_, estado) => LancarEstoqueScreen(
            produtoInicialId: estado.uri.queryParameters['produto'],
          ),
        ),
        GoRoute(
          path: ':id',
          parentNavigatorKey: chaveRaiz,
          builder: (_, estado) =>
              ProdutosDetalhesScreen(idProduto: estado.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'editar',
              parentNavigatorKey: chaveRaiz,
              builder: (_, estado) => ProdutosFormularioScreen(
                idProduto: estado.pathParameters['id'],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static GoRoute _rotaEmConstrucao(ModuloApp modulo) {
    return GoRoute(
      path: modulo.rota,
      pageBuilder: (_, estado) => NoTransitionPage(
        key: estado.pageKey,
        child: EmConstrucaoScreen(titulo: modulo.titulo),
      ),
    );
  }
}
