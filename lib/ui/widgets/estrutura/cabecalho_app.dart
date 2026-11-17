// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Ação do canto esquerdo do [CabecalhoApp].
enum AcaoCabecalho { menu, voltar, nenhuma }

/// Cabeçalho vinho com borda inferior arredondada, usado em todas as telas.
class CabecalhoApp extends StatelessWidget {
  const CabecalhoApp({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acao = AcaoCabecalho.voltar,
    this.onMenu,
    this.onVoltar,
    this.fim,
    this.cor = CoresApp.primaria,
  });

  final String titulo;

  /// Texto pequeno abaixo do título (ex.: "PASSO 1 DE 2").
  final String? subtitulo;
  final AcaoCabecalho acao;
  final VoidCallback? onMenu;

  /// Padrão: fecha a tela atual.
  final VoidCallback? onVoltar;

  /// Widget do canto direito (ex.: botão de ação, avatar).
  final Widget? fim;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              SizedBox(width: 64, child: _acaoInicio(context)),
              Expanded(child: _titulos(context)),
              SizedBox(width: 64, child: Center(child: fim)),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _acaoInicio(BuildContext context) {
    return switch (acao) {
      AcaoCabecalho.nenhuma => null,
      AcaoCabecalho.menu => IconButton(
        tooltip: 'Abrir menu',
        onPressed: onMenu,
        icon: const Icon(
          Icons.menu_rounded,
          color: CoresApp.sobrePrimaria,
          size: 30,
        ),
      ),
      AcaoCabecalho.voltar => IconButton(
        tooltip: 'Voltar',
        onPressed: onVoltar ?? () => Navigator.of(context).maybePop(),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: CoresApp.sobrePrimaria,
          size: 28,
        ),
      ),
    };
  }

  Widget _titulos(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: estilos.titleLarge?.copyWith(
            color: CoresApp.sobrePrimaria,
            fontSize: 22,
          ),
        ),
        if (subtitulo != null)
          Text(
            subtitulo!.toUpperCase(),
            style: estilos.labelSmall?.copyWith(
              color: CoresApp.sobrePrimaria.withOpacity(0.85),
              letterSpacing: 1.2,
            ),
          ),
      ],
    );
  }
}
