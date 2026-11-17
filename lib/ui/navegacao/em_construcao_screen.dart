// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/navegacao/casca/casca_principal_screen.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';

/// Tela principal provisória de um módulo ainda não construído.
/// Cada fase troca esta tela pela tela real do módulo no roteador.
class EmConstrucaoScreen extends StatelessWidget {
  const EmConstrucaoScreen({super.key, required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CabecalhoApp(
          titulo: titulo,
          acao: AcaoCabecalho.menu,
          onMenu: () => CascaPrincipalScreen.abrirMenu(context),
        ),
        Expanded(child: EstadoEmConstrucaoApp(modulo: titulo)),
      ],
    );
  }
}
