// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/core/model/lembrete_recompra.dart';
import 'package:sou_consultora/core/model/resumo_inicio.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';

/// "Lembrete de recompra": até 3 clientes cujo produto está no fim, com o
/// WhatsApp (mensagem pronta) e Ver todos.
class SecaoLembretes extends StatelessWidget {
  const SecaoLembretes({
    super.key,
    required this.lembretes,
    required this.onWhatsapp,
    required this.onVerTodos,
  });

  final List<LembreteAtivo> lembretes;
  final ValueChanged<LembreteAtivo> onWhatsapp;
  final VoidCallback onVerTodos;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Lembrete de recompra', style: estilos.titleLarge),
            ),
            TextButton(
              onPressed: onVerTodos,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ver todos'),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CoresApp.superficie,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: CoresApp.contorno),
          ),
          child: lembretes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Nenhuma cliente precisando recomprar agora. Os produtos '
                    'com duração prevista aparecem aqui perto de acabar.',
                    style: estilos.bodyMedium?.copyWith(
                      color: CoresApp.sobreSuperficieVariante,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < lembretes.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: CoresApp.contorno,
                        ),
                      _Linha(
                        ativo: lembretes[i],
                        onWhatsapp: () => onWhatsapp(lembretes[i]),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.ativo, required this.onWhatsapp});

  final LembreteAtivo ativo;
  final VoidCallback onWhatsapp;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final lembrete = ativo.lembrete;
    final dias = ativo.diasDesdeCompra;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          AvatarApp(
            iniciais: Cliente.iniciaisDe(lembrete.clienteNome),
            tamanho: TamanhoAvatar.miniatura,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(lembrete.clienteNome, style: estilos.titleMedium),
                    SeloStatusApp(
                      rotulo: ativo.situacao.rotulo,
                      status: ativo.situacao == SituacaoLembrete.acabando
                          ? StatusSelo.perigo
                          : StatusSelo.alerta,
                    ),
                  ],
                ),
                Text(
                  '${lembrete.produtoNome} • '
                  '${dias == 1 ? 'há 1 dia' : 'há $dias dias'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: estilos.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Lembrar ${lembrete.clienteNome} no WhatsApp',
            onPressed: onWhatsapp,
            style: IconButton.styleFrom(
              backgroundColor: CoresApp.primariaSuave,
            ),
            icon: const Icon(Icons.chat_outlined, color: CoresApp.primaria),
          ),
        ],
      ),
    );
  }
}
