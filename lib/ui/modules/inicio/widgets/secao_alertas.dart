// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/resumo_inicio.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/botoes/botao_app.dart';
import 'package:sou_consultora/ui/widgets/estrutura/titulo_secao_app.dart';

/// "Alertas de hoje": boletos que venceram, vencem hoje ou amanhã (Ver
/// fatura) e as vendas atrasadas (Cobrar agora).
class SecaoAlertas extends StatelessWidget {
  const SecaoAlertas({
    super.key,
    required this.resumo,
    required this.onVerFatura,
    required this.onCobrar,
  });

  final ResumoInicio resumo;
  final ValueChanged<String> onVerFatura;
  final VoidCallback onCobrar;

  /// "VENCEU HÁ 3 DIAS", "VENCE HOJE", "VENCE AMANHÃ".
  static String seloDe(AlertaBoleto alerta) => switch (alerta.diasParaVencer) {
    1 => 'VENCE AMANHÃ',
    0 => 'VENCE HOJE',
    -1 => 'VENCEU ONTEM',
    final dias => 'VENCEU HÁ ${-dias} DIAS',
  };

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final atrasadas = resumo.atrasadas;
    final qtd = resumo.qtdAlertas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Flexible(
              child: TituloSecaoApp(
                titulo: 'Alertas de hoje',
                icone: Icons.notifications_outlined,
              ),
            ),
            if (qtd > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: CoresApp.primaria,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$qtd',
                  style: estilos.labelLarge?.copyWith(
                    color: CoresApp.sobrePrimaria,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (qtd == 0)
          _Cartao(
            icone: Icons.check_circle_outline_rounded,
            corIcone: CoresApp.sucesso,
            fundoIcone: CoresApp.sucessoContainer,
            selo: null,
            titulo: 'Nada para hoje',
            subtitulo: 'Nenhum boleto vencendo nem cobrança atrasada.',
          ),
        for (final alerta in resumo.alertasBoletos) ...[
          _Cartao(
            icone: Icons.receipt_long_outlined,
            corIcone: alerta.diasParaVencer < 0
                ? CoresApp.perigo
                : CoresApp.alerta,
            fundoIcone: alerta.diasParaVencer < 0
                ? CoresApp.perigoContainer
                : CoresApp.alertaContainer,
            selo: seloDe(alerta),
            perigo: alerta.diasParaVencer < 0,
            titulo: alerta.boleto.fornecedorNome,
            subtitulo: FormatadorMoeda.formatar(alerta.boleto.valor),
            acao: BotaoApp.contorno(
              rotulo: 'Ver fatura',
              tamanho: TamanhoBotao.compacto,
              expande: false,
              onPressed: () => onVerFatura(alerta.boleto.id),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (atrasadas != null)
          _Cartao(
            icone: Icons.notifications_active_outlined,
            corIcone: CoresApp.perigo,
            fundoIcone: CoresApp.perigoContainer,
            selo: atrasadas.qtdClientes == 1
                ? '1 CLIENTE'
                : '${atrasadas.qtdClientes} CLIENTES',
            perigo: true,
            titulo: 'Vendas Atrasadas',
            subtitulo: 'Total ${FormatadorMoeda.formatar(atrasadas.total)}',
            acao: BotaoApp(
              rotulo: 'Cobrar',
              tamanho: TamanhoBotao.compacto,
              expande: false,
              onPressed: onCobrar,
            ),
          ),
      ],
    );
  }
}

class _Cartao extends StatelessWidget {
  const _Cartao({
    required this.icone,
    required this.corIcone,
    required this.fundoIcone,
    required this.selo,
    required this.titulo,
    required this.subtitulo,
    this.perigo = false,
    this.acao,
  });

  final IconData icone;
  final Color corIcone;
  final Color fundoIcone;
  final String? selo;
  final String titulo;
  final String subtitulo;
  final bool perigo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final rotulo = selo;
    final botao = acao;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoresApp.contorno),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: fundoIcone,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icone, color: corIcone, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rotulo != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: perigo
                          ? CoresApp.perigoContainer
                          : CoresApp.alertaContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rotulo,
                      style: estilos.labelSmall?.copyWith(
                        color: perigo ? CoresApp.perigo : CoresApp.alerta,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                // Até 2 linhas: o botão ao lado ("Cobrar agora") é largo.
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: estilos.titleMedium,
                ),
                Text(
                  subtitulo,
                  style: estilos.bodyMedium?.copyWith(
                    color: rotulo == null
                        ? CoresApp.sobreSuperficieVariante
                        : CoresApp.primaria,
                    fontWeight: rotulo == null ? null : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (botao != null) ...[const SizedBox(width: 8), botao],
        ],
      ),
    );
  }
}
