// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/navegacao/casca/casca_principal_screen.dart';
import 'package:sou_consultora/ui/widgets/estados/estados_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/cabecalho_app.dart';

/// Tela provisória de algo ainda não construído.
/// Cada fase troca esta tela pela tela real no roteador.
class EmConstrucaoScreen extends StatelessWidget {
  const EmConstrucaoScreen({super.key, required this.titulo}) : porCima = false;

  /// Versão que abre por cima (sem a barra), com a seta de voltar.
  const EmConstrucaoScreen.porCima({super.key, required this.titulo})
    : porCima = true;

  final String titulo;
  final bool porCima;

  @override
  Widget build(BuildContext context) {
    final conteudo = Column(
      children: [
        CabecalhoApp(
          titulo: titulo,
          acao: porCima ? AcaoCabecalho.voltar : AcaoCabecalho.menu,
          onMenu: porCima
              ? null
              : () => CascaPrincipalScreen.abrirMenu(context),
        ),
        Expanded(child: EstadoEmConstrucaoApp(modulo: titulo)),
      ],
    );
    return porCima ? Scaffold(body: conteudo) : conteudo;
  }
}
