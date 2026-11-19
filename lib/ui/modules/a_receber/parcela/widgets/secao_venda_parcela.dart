// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/core/model/venda.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/vendas/widgets/selos_venda.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/titulo_secao_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';

/// Seção "Venda": a venda de origem (abre os detalhes) e as parcelas dela
/// (tocar abre a outra parcela; a atual mostra "Você está aqui").
class SecaoVendaParcela extends StatelessWidget {
  const SecaoVendaParcela({
    super.key,
    required this.venda,
    required this.parcelas,
    required this.idAtual,
    required this.hoje,
    required this.onVenda,
    required this.onParcela,
  });

  final ResumoVenda venda;
  final List<ResumoParcela> parcelas;
  final String idAtual;
  final DateTime hoje;
  final VoidCallback onVenda;
  final ValueChanged<String> onParcela;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final unidades = venda.qtdUnidades == 1
        ? '1 un'
        : '${venda.qtdUnidades} un';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TituloSecaoApp(
          titulo: 'Venda',
          icone: Icons.shopping_bag_outlined,
        ),
        const SizedBox(height: 12),
        CartaoApp(
          filho: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                button: true,
                label: 'Abrir venda ${venda.codigoTexto}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onVenda,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: CoresApp.alertaContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: CoresApp.alerta,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Venda ${venda.codigoTexto}',
                              style: estilos.titleMedium,
                            ),
                            Text(
                              '${FormatadorData.curta(venda.dataVenda)} • '
                              '$unidades • Total '
                              '${FormatadorMoeda.formatar(venda.total)}',
                              style: estilos.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
              const Divider(height: 32, color: CoresApp.contorno),
              Text(
                'PARCELAS DA VENDA (${parcelas.length}X)',
                style: estilos.labelLarge?.copyWith(
                  color: CoresApp.sobreSuperficieVariante,
                ),
              ),
              const SizedBox(height: 8),
              for (final parcela in parcelas)
                _LinhaParcela(
                  parcela: parcela,
                  atual: parcela.id == idAtual,
                  hoje: hoje,
                  onTap: () => onParcela(parcela.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinhaParcela extends StatelessWidget {
  const _LinhaParcela({
    required this.parcela,
    required this.atual,
    required this.hoje,
    required this.onTap,
  });

  final ResumoParcela parcela;
  final bool atual;
  final DateTime hoje;
  final VoidCallback onTap;

  String get _descricao {
    if (atual) return 'Você está aqui';
    if (parcela.paga) {
      final pagoEm = parcela.ultimoPagamento;
      return pagoEm == null
          ? 'Paga'
          : 'Paga em ${FormatadorData.diaMesNumerico(pagoEm)}';
    }
    return 'Vence ${FormatadorData.diaMesNumerico(parcela.vencimento)}';
  }

  IconData get _icone {
    if (parcela.paga) return Icons.check_circle_rounded;
    if (atual) return Icons.radio_button_checked_rounded;
    return Icons.radio_button_unchecked_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final info = Row(
      children: [
        Icon(
          _icone,
          color: parcela.paga ? CoresApp.sucesso : CoresApp.primaria,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${parcela.numero}ª parcela • '
                '${FormatadorMoeda.formatar(parcela.valor)}',
                style: estilos.titleSmall,
              ),
              Text(
                _descricao,
                style: estilos.bodySmall?.copyWith(
                  color: atual ? CoresApp.primaria : null,
                ),
              ),
            ],
          ),
        ),
        SeloStatusParcela(
          tamanho: TamanhoSelo.pagina,
          status: parcela.status(hoje: hoje),
        ),
      ],
    );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: atual
          ? BoxDecoration(
              color: CoresApp.primariaSuave.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CoresApp.contorno),
            )
          : null,
      child: atual
          ? info
          : Semantics(
              button: true,
              label: 'Abrir parcela ${parcela.textoNumero}',
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: info,
              ),
            ),
    );
  }
}
