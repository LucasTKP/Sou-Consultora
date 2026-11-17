// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/ui/modules/cadastro/cadastro_screen.dart';
import 'package:sou_consultora/ui/modules/login/acesso_login_screen.dart';
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
            for (final modulo in RotasApp.modulos) _rotaEmConstrucao(modulo),
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
