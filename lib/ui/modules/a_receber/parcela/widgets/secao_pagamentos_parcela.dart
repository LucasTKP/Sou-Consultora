// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/pagamento.dart';
import 'package:sou_consultora/core/model/parcela.dart';
import 'package:sou_consultora/ui/formatadores/formatador_data.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/modules/vendas/widgets/selos_venda.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/badges/selo_status_app.dart';
import 'package:sou_consultora/ui/widgets/cards/cartao_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/titulo_secao_app.dart';

/// "Pagamentos desta parcela": cada pagamento e, se houver, o saldo restante.
class SecaoPagamentosParcela extends StatelessWidget {
  const SecaoPagamentosParcela({
    super.key,
    required this.parcela,
    required this.pagamentos,
    required this.hoje,
    this.onEditar,
  });

  final ResumoParcela parcela;
  final List<Pagamento> pagamentos;
  final DateTime hoje;

  /// Corrige um pagamento anotado errado (valor, forma, data). Null: sem botão.
  final ValueChanged<Pagamento>? onEditar;

  @override
  Widget build(BuildContext context) {
    final linhas = <Widget>[
      for (final pagamento in pagamentos)
        _LinhaPagamento(
          pagamento: pagamento,
          onEditar: onEditar == null ? null : () => onEditar!(pagamento),
        ),
      if (!parcela.paga) _LinhaSaldo(parcela: parcela, hoje: hoje),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TituloSecaoApp(
          titulo: 'Pagamentos desta parcela',
          icone: Icons.receipt_long_outlined,
        ),
        const SizedBox(height: 12),
        if (pagamentos.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Nenhum pagamento registrado ainda.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: CoresApp.sobreSuperficieVariante),
            ),
          ),
        CartaoApp(
          filho: Column(
            children: [
              for (var i = 0; i < linhas.length; i++) ...[
                if (i > 0) const Divider(height: 24, color: CoresApp.contorno),
                linhas[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LinhaPagamento extends StatelessWidget {
  const _LinhaPagamento({required this.pagamento, this.onEditar});

  final Pagamento pagamento;
  final VoidCallback? onEditar;

  @override
  Widget build(BuildContext context) {
    final observacao = pagamento.observacao;
    final editar = onEditar;
    return _Linha(
      icone: Icons.check_circle_rounded,
      corIcone: CoresApp.sucesso,
      fundoIcone: CoresApp.sucessoContainer,
      valor: FormatadorMoeda.formatar(pagamento.valor),
      descricao:
          'Via ${pagamento.forma.rotulo} • '
          '${FormatadorData.diaMesNumerico(pagamento.data)}'
          '${observacao == null ? '' : ' • $observacao'}',
      selo: const SeloStatusApp(
        tamanho: TamanhoSelo.pagina,
        rotulo: 'Recebido',
        status: StatusSelo.sucesso,
      ),
      acao: editar == null
          ? null
          : IconButton(
              tooltip: 'Editar pagamento',
              icon: const Icon(Icons.edit_outlined),
              color: CoresApp.primaria,
              onPressed: editar,
            ),
    );
  }
}

class _LinhaSaldo extends StatelessWidget {
  const _LinhaSaldo({required this.parcela, required this.hoje});

  final ResumoParcela parcela;
  final DateTime hoje;

  @override
  Widget build(BuildContext context) {
    final status = parcela.status(hoje: hoje);
    final atrasada = status == StatusParcela.atrasada;
    final dia = FormatadorData.diaMesNumerico(parcela.vencimento);
    return _Linha(
      icone: Icons.event_busy_outlined,
      corIcone: atrasada ? CoresApp.perigo : CoresApp.alerta,
      fundoIcone: atrasada
          ? CoresApp.perigoContainer
          : CoresApp.alertaContainer,
      valor: FormatadorMoeda.formatar(parcela.saldo),
      descricao: atrasada
          ? 'Saldo restante • venceu $dia'
          : 'Saldo restante • vence $dia',
      corDescricao: atrasada ? CoresApp.perigo : null,
      selo: SeloStatusParcela(tamanho: TamanhoSelo.pagina, status: status),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.icone,
    required this.corIcone,
    required this.fundoIcone,
    required this.valor,
    required this.descricao,
    required this.selo,
    this.corDescricao,
    this.acao,
  });

  final IconData icone;
  final Color corIcone;
  final Color fundoIcone;
  final String valor;
  final String descricao;
  final Color? corDescricao;
  final Widget selo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: fundoIcone,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icone, color: corIcone),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(valor, style: estilos.titleMedium),
              Text(
                descricao,
                style: estilos.bodySmall?.copyWith(color: corDescricao),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        selo,
        ?acao,
      ],
    );
  }
}
