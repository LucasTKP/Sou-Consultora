// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/temas/espacos_app.dart';

/// Folha inferior do app: alça, título, subtítulo, botão fechar e conteúdo.
/// O [rodape], quando informado, fica fixo abaixo do conteúdo rolável
/// (ex.: botão "Cadastrar").
abstract final class FolhaInferiorApp {
  /// Fração da altura da tela que toda folha ocupa.
  static const alturaRelativa = 0.7;

  /// Abre a folha e devolve o valor passado ao `Navigator.pop` (ou null ao fechar).
  static Future<T?> mostrar<T>({
    required BuildContext context,
    required String titulo,
    required WidgetBuilder conteudo,
    String? subtitulo,
    Widget? rodape,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: CoresApp.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (contexto) => _CorpoFolha(
        titulo: titulo,
        subtitulo: subtitulo,
        conteudo: conteudo(contexto),
        rodape: rodape,
      ),
    );
  }
}

class _CorpoFolha extends StatelessWidget {
  const _CorpoFolha({
    required this.titulo,
    required this.conteudo,
    this.subtitulo,
    this.rodape,
  });

  final String titulo;
  final String? subtitulo;
  final Widget conteudo;
  final Widget? rodape;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final consulta = MediaQuery.of(context);
    final teclado = consulta.viewInsets.bottom;
    // Altura fixa de 70% da tela, sem encolher com o conteúdo; com o teclado
    // aberto, só cede o que o teclado e a barra de status tomam.
    final altura = (consulta.size.height * FolhaInferiorApp.alturaRelativa)
        .clamp(0.0, consulta.size.height - teclado - consulta.padding.top);
    return Padding(
      padding: EdgeInsets.only(bottom: teclado),
      child: SizedBox(
        height: altura,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: CoresApp.primariaSuave,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: estilos.headlineSmall),
                        if (subtitulo != null)
                          Text(subtitulo!, style: estilos.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 24),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: conteudo,
              ),
            ),
            if (rodape != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: rodape,
              ),
            // Espaço extra para celulares com botões de navegação na base.
            SizedBox(height: teclado > 0 ? 24 : 48 + EspacosApp.folgaInferior),
          ],
        ),
      ),
    );
  }
}
