import 'package:flutter/widgets.dart';
import 'package:sou_consultora/core/model/resumo_cliente.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/modules/clientes/widgets/selo_situacao_cliente.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';

/// Card da cliente na lista: iniciais, nome, linha de apoio e selo de situação.
class CartaoCliente extends StatelessWidget {
  const CartaoCliente({
    super.key,
    required this.cliente,
    required this.hoje,
    required this.onTap,
  });

  final ResumoCliente cliente;
  final DateTime hoje;
  final VoidCallback onTap;

  String get _apoio {
    return switch (cliente.situacao(hoje)) {
      SituacaoCliente.atrasada => 'Parcela atrasada',
      SituacaoCliente.venceHoje => 'Parcela vence hoje',
      SituacaoCliente.aniversario =>
        'Faz aniversário dia ${cliente.dataNascimento!.day}',
      SituacaoCliente.emDia => _apoioEmDia,
    };
  }

  String get _apoioEmDia {
    final ultima = cliente.ultimaCompra;
    if (ultima != null) {
      return 'Última compra ${FormatadorData.relativo(ultima, hoje: hoje)}';
    }
    return 'Cliente desde ${FormatadorData.mesAno(cliente.criadaEm)}';
  }

  @override
  Widget build(BuildContext context) {
    final aniversario = cliente.situacao(hoje) == SituacaoCliente.aniversario;
    return CartaoListaApp(
      titulo: cliente.nome,
      subtitulo: _apoio,
      inicio: AvatarApp(
        iniciais: cliente.iniciais,
        corFundo: aniversario ? CoresApp.alertaContainer : null,
      ),
      selo: SeloSituacaoCliente(cliente: cliente, hoje: hoje),
      onTap: onTap,
    );
  }
}
