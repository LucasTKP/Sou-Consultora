// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Item do [GrupoNavegacaoApp]: ícone em quadrado colorido, título, descrição e seta.
class ItemNavegacaoApp {
  const ItemNavegacaoApp({
    required this.icone,
    required this.titulo,
    required this.onTap,
    this.descricao,
    this.corIcone = CoresApp.primaria,
    this.corFundoIcone = CoresApp.primariaSuave,
  });

  final IconData icone;
  final String titulo;
  final String? descricao;
  final VoidCallback onTap;
  final Color corIcone;
  final Color corFundoIcone;
}

/// Card com itens de navegação separados por linha
/// (ex.: Dados cadastrais / Compras da cliente / Extrato & parcelas).
class GrupoNavegacaoApp extends StatelessWidget {
  const GrupoNavegacaoApp({super.key, required this.itens});

  final List<ItemNavegacaoApp> itens;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CoresApp.superficie,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: CoresApp.primariaSuave),
      ),
      child: Column(
        children: [
          for (var i = 0; i < itens.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _LinhaNavegacao(item: itens[i]),
          ],
        ],
      ),
    );
  }
}

class _LinhaNavegacao extends StatelessWidget {
  const _LinhaNavegacao({required this.item});

  final ItemNavegacaoApp item;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.corFundoIcone,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icone, color: item.corIcone),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.titulo, style: estilos.titleMedium),
                  if (item.descricao != null)
                    Text(item.descricao!, style: estilos.bodySmall),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: CoresApp.sobreSuperficieVariante,
            ),
          ],
        ),
      ),
    );
  }
}
