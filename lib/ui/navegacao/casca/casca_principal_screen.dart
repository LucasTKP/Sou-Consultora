// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/ui/navegacao/casca/casca_principal_cubit.dart';
import 'package:sou_consultora/ui/navegacao/casca/casca_principal_state.dart';
import 'package:sou_consultora/ui/navegacao/casca/widgets/barra_inferior.dart';
import 'package:sou_consultora/ui/navegacao/casca/widgets/menu_lateral.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';

/// Casca das telas principais: barra inferior, menu lateral e botão voltar.
///
/// As telas principais **não** criam `Scaffold` própria; para abrir o menu
/// usam [CascaPrincipalScreen.abrirMenu].
class CascaPrincipalScreen extends StatelessWidget {
  const CascaPrincipalScreen({
    super.key,
    required this.caminhoAtual,
    required this.filho,
  });

  final String caminhoAtual;
  final Widget filho;

  /// Abre o menu lateral a partir de qualquer tela dentro da casca.
  static void abrirMenu(BuildContext context) {
    context.findAncestorStateOfType<_CascaVistaState>()?._abrirMenu();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CascaPrincipalCubit(),
      child: _CascaVista(caminhoAtual: caminhoAtual, filho: filho),
    );
  }
}

class _CascaVista extends StatefulWidget {
  const _CascaVista({required this.caminhoAtual, required this.filho});

  final String caminhoAtual;
  final Widget filho;

  @override
  State<_CascaVista> createState() => _CascaVistaState();
}

class _CascaVistaState extends State<_CascaVista> {
  final _chaveScaffold = GlobalKey<ScaffoldState>();

  bool get _noInicio => widget.caminhoAtual == RotasApp.inicio;

  void _abrirMenu() => _chaveScaffold.currentState?.openDrawer();

  void _aoSelecionarItem(ItemBarra item) =>
      context.go(RotasApp.rotaDoItem(item));

  /// Abas da barra trocam de lugar. O resto abre por cima, para o voltar
  /// devolver a aba (e a barra) de onde a pessoa saiu.
  void _aoNavegarPeloMenu(String rota) {
    _chaveScaffold.currentState?.closeDrawer();
    final naBarra = RotasApp.itemAtivo(rota) != null;
    if (naBarra && rota != RotasApp.perfil) {
      context.go(rota);
      return;
    }
    context.push(rota);
  }

  /// Ordem do voltar: menu aberto → fecha; tela por cima → fecha ela;
  /// aba que não é o Início → Início; no Início → sai do app.
  void _aoVoltar(bool saiu, Object? _) {
    if (saiu) return;
    final scaffold = _chaveScaffold.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
      return;
    }
    if (widget.caminhoAtual == RotasApp.inicio) return;
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RotasApp.inicio);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _noInicio,
      onPopInvokedWithResult: _aoVoltar,
      child: BlocBuilder<CascaPrincipalCubit, CascaPrincipalState>(
        builder: (context, estado) {
          final itemAtivo = RotasApp.itemAtivo(widget.caminhoAtual);
          // Só as cinco abas têm a barra. As outras telas voltam para ela.
          final naBarra = itemAtivo != null;
          return Scaffold(
            key: _chaveScaffold,
            extendBody: naBarra,
            drawer: MenuLateral(
              resumo: estado.resumo,
              caminhoAtual: widget.caminhoAtual,
              onNavegar: _aoNavegarPeloMenu,
              qtdAtrasadas: estado.qtdAtrasadas,
            ),
            body: widget.filho,
            bottomNavigationBar: naBarra
                ? BarraInferior(
                    itemAtivo: itemAtivo,
                    onSelecionar: _aoSelecionarItem,
                  )
                : null,
          );
        },
      ),
    );
  }
}
