// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/resumo_cliente.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';
import 'package:sou_consultora/ui/widgets/cards/linha_situacao_app.dart';

/// Card da cliente na lista: iniciais, nome e uma linha de situação.
///
/// A situação vai em texto colorido, sem selo: "2 atrasadas · R$ 1.250,00",
/// "Vence hoje · R$ 300,00", "Faz aniversário dia 12" ou "Em dia · Última compra…".
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

  /// Parte em destaque da linha e a cor dela.
  (String, Color) get _status {
    return switch (cliente.situacao(hoje)) {
      SituacaoCliente.atrasada => (
        '${_atrasadas(cliente.qtdAtrasadas)} · '
            '${FormatadorMoeda.formatar(cliente.valorAtrasado)}',
        CoresApp.perigo,
      ),
      SituacaoCliente.venceHoje => (
        'Vence hoje · ${FormatadorMoeda.formatar(cliente.valorVenceHoje)}',
        CoresApp.alerta,
      ),
      SituacaoCliente.aniversario => (
        'Faz aniversário dia ${cliente.dataNascimento!.day}',
        CoresApp.alerta,
      ),
      SituacaoCliente.emDia => ('Em dia', CoresApp.sucesso),
    };
  }

  /// Só o "Em dia" leva a última compra ao lado; os alertas já dizem o que importa.
  String? get _complemento {
    if (cliente.situacao(hoje) != SituacaoCliente.emDia) return null;
    final ultima = cliente.ultimaCompra;
    if (ultima != null) {
      return 'Última compra ${FormatadorData.relativo(ultima, hoje: hoje)}';
    }
    return 'Cliente desde ${FormatadorData.mesAno(cliente.criadaEm)}';
  }

  static String _atrasadas(int quantidade) {
    return quantidade == 1 ? '1 atrasada' : '$quantidade atrasadas';
  }

  @override
  Widget build(BuildContext context) {
    final (status, cor) = _status;
    final complemento = _complemento;
    final aniversario = cliente.situacao(hoje) == SituacaoCliente.aniversario;
    return CartaoListaApp(
      titulo: cliente.nome,
      linhaInferior: LinhaSituacaoApp(
        status: status,
        cor: cor,
        detalhes: [?complemento],
      ),
      inicio: AvatarApp(
        iniciais: cliente.iniciais,
        corFundo: aniversario ? CoresApp.alertaContainer : null,
      ),
      onTap: onTap,
    );
  }
}
