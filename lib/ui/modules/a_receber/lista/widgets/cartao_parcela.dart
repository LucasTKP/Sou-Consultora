// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/core/model/filtro_recebimentos.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_lista_app.dart';

/// Card da parcela em A receber: cliente, qual parcela, selo e valor.
class CartaoParcela extends StatelessWidget {
  const CartaoParcela({
    super.key,
    required this.parcela,
    required this.hoje,
    required this.onTap,
  });

  final ResumoParcela parcela;
  final DateTime hoje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (rotulo, status) = seloDe(parcela, hoje: hoje);
    return CartaoListaApp(
      titulo: parcela.clienteNome,
      subtitulo:
          '${parcela.textoCurto} • '
          '${FormatadorMoeda.formatar(FiltroRecebimentos.valorExibido(parcela))}',
      inicio: AvatarApp(
        iniciais: Cliente.iniciaisDe(parcela.clienteNome),
        tamanho: TamanhoAvatar.miniatura,
      ),
      selo: SeloStatusApp(rotulo: rotulo, status: status),
      onTap: onTap,
    );
  }

  /// "Atrasado (15/10)", "Vence hoje", "Venc. 25/10", "Pago em 18/10".
  static (String, StatusSelo) seloDe(
    ResumoParcela parcela, {
    required DateTime hoje,
  }) {
    final venc = _diaMes(parcela.vencimento);
    if (parcela.paga) {
      final pagoEm = parcela.ultimoPagamento;
      return (
        pagoEm == null ? 'Pago' : 'Pago em ${_diaMes(pagoEm)}',
        StatusSelo.sucesso,
      );
    }
    if (parcela.venceHoje(hoje: hoje)) return ('Vence hoje', StatusSelo.alerta);
    if (parcela.status(hoje: hoje) == StatusParcela.atrasada) {
      return ('Atrasado ($venc)', StatusSelo.perigo);
    }
    if (parcela.valorPago > 0) return ('Parcial • $venc', StatusSelo.primario);
    return ('Venc. $venc', StatusSelo.neutro);
  }

  static String _diaMes(DateTime d) => FormatadorData.diaMesNumerico(d);
}
