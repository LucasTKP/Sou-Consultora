// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/dialog/folha_inferior_app.dart';

/// Botão de ordenar: ícone de setas e o nome da ordem atual. O toque abre a
/// folha com as opções; a escolhida fica marcada.
class BotaoOrdenacaoApp<T> extends StatelessWidget {
  const BotaoOrdenacaoApp({
    super.key,
    required this.opcoes,
    required this.rotuloDe,
    required this.valor,
    required this.onChanged,
  });

  final List<T> opcoes;
  final String Function(T opcao) rotuloDe;
  final T valor;
  final ValueChanged<T> onChanged;

  Future<void> _abrir(BuildContext context) async {
    final escolhida = await FolhaInferiorApp.mostrar<T>(
      context: context,
      titulo: 'Ordenar',
      conteudo: (folha) => Column(
        children: [
          for (final opcao in opcoes)
            _Opcao(
              rotulo: rotuloDe(opcao),
              selecionada: opcao == valor,
              onTap: () => Navigator.of(folha).pop(opcao),
            ),
        ],
      ),
    );
    if (escolhida != null && context.mounted) onChanged(escolhida);
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _abrir(context),
      icon: const Icon(Icons.swap_vert_rounded),
      label: Text(
        rotuloDe(valor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _Opcao extends StatelessWidget {
  const _Opcao({
    required this.rotulo,
    required this.selecionada,
    required this.onTap,
  });

  final String rotulo;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: selecionada ? CoresApp.primariaSuave : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rotulo,
                    style: estilos.bodyLarge?.copyWith(
                      fontWeight: selecionada
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: selecionada ? CoresApp.primariaEscura : null,
                    ),
                  ),
                ),
                if (selecionada)
                  const Icon(Icons.check_rounded, color: CoresApp.primaria),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
