// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sou_consultora/ui/navegacao/casca/casca_principal_cubit.dart';
import 'package:sou_consultora/ui/navegacao/casca/casca_principal_state.dart';
import 'package:sou_consultora/ui/navegacao/casca/widgets/barra_inferior.dart';
import 'package:sou_consultora/ui/navegacao/casca/widgets/menu_lateral.dart';
import 'package:sou_consultora/ui/navegacao/rotas_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/dialogo_confirmacao_app.dart';

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
      create: (_) => CascaPrincipalCubit()..carregarVersao(),
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

  /// Perfil abre por cima (push) para o voltar retornar a esta tela.
  void _aoNavegarPeloMenu(String rota) {
    _chaveScaffold.currentState?.closeDrawer();
    if (rota == RotasApp.perfil) {
      context.push(rota);
      return;
    }
    context.go(rota);
  }

  Future<void> _aoSair() async {
    final confirmou = await DialogoConfirmacaoApp.mostrar(
      context: context,
      titulo: 'Sair da conta?',
      mensagem: 'Você precisará entrar novamente com Google ou Apple.',
      rotuloConfirmar: 'Sair',
      perigo: true,
    );
    if (!confirmou || !mounted) return;
    await context.read<CascaPrincipalCubit>().sair();
  }

  /// Ordem do voltar: menu aberto → fecha; fora do Início → Início; no Início → sai do app.
  void _aoVoltar(bool saiu, Object? _) {
    if (saiu) return;
    final scaffold = _chaveScaffold.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
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
        builder: (context, estado) => Scaffold(
          key: _chaveScaffold,
          extendBody: true,
          drawer: MenuLateral(
            resumo: estado.resumo,
            versao: estado.versao,
            caminhoAtual: widget.caminhoAtual,
            onNavegar: _aoNavegarPeloMenu,
            onSair: _aoSair,
          ),
          body: widget.filho,
          bottomNavigationBar: BarraInferior(
            itemAtivo: RotasApp.itemAtivo(widget.caminhoAtual),
            onSelecionar: _aoSelecionarItem,
          ),
        ),
      ),
    );
  }
}
