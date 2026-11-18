// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/core/model/consultora.dart';
import 'package:sou_consultora/core/model/resumo_inicio.dart';
import 'package:sou_consultora/ui/formatadores/formatador_moeda.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/avatares/avatar_app.dart';

/// Topo rosa do Início: foto e cumprimento, menu, Vendido no mês e os três
/// números (Vendas, Recebido e Boletos), que abrem os módulos.
class CabecalhoInicio extends StatelessWidget {
  const CabecalhoInicio({
    super.key,
    required this.cumprimento,
    required this.consultora,
    required this.resumo,
    required this.onMenu,
    required this.onVendas,
    required this.onRecebido,
    required this.onBoletos,
  });

  final String cumprimento;
  final Consultora? consultora;

  /// Null enquanto carrega (os números ficam com "—").
  final ResumoInicio? resumo;
  final VoidCallback onMenu;
  final VoidCallback onVendas;
  final VoidCallback onRecebido;
  final VoidCallback onBoletos;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final numeros = resumo;
    const claro = CoresApp.sobrePrimaria;
    return Material(
      color: CoresApp.primaria,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 24),
          child: Column(
            children: [
              Row(
                children: [
                  AvatarApp(
                    urlImagem: consultora?.urlFoto,
                    iniciais: Cliente.iniciaisDe(consultora?.nome ?? ''),
                    tamanho: TamanhoAvatar.card,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cumprimento,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: estilos.titleLarge?.copyWith(color: claro),
                    ),
                  ),
                  Material(
                    color: claro.withOpacity(0.18),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Abrir menu',
                      onPressed: onMenu,
                      icon: const Icon(Icons.menu_rounded, color: claro),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Vendido no mês',
                style: estilos.titleSmall?.copyWith(
                  color: claro.withOpacity(0.85),
                ),
              ),
              FittedBox(
                child: Text(
                  numeros == null
                      ? '—'
                      : FormatadorMoeda.formatar(numeros.vendidoNoMes),
                  style: estilos.displaySmall?.copyWith(color: claro),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Numero(
                      titulo: 'Vendas',
                      valor: numeros == null
                          ? '—'
                          : '${numeros.qtdVendasNoMes}',
                      legenda: numeros?.qtdVendasNoMes == 1
                          ? 'pedido feito'
                          : 'pedidos feitos',
                      onTap: onVendas,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Numero(
                      titulo: 'Recebido',
                      valor: numeros == null
                          ? '—'
                          : FormatadorMoeda.formatarSemCentavos(
                              numeros.recebidoNoMes,
                            ),
                      legenda: 'neste mês',
                      onTap: onRecebido,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Numero(
                      titulo: 'Boletos',
                      valor: numeros == null
                          ? '—'
                          : FormatadorMoeda.formatarSemCentavos(
                              numeros.boletosNoMes,
                            ),
                      legenda: 'vencem no mês',
                      onTap: onBoletos,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({
    required this.titulo,
    required this.valor,
    required this.legenda,
    required this.onTap,
  });

  final String titulo;
  final String valor;
  final String legenda;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    const claro = CoresApp.sobrePrimaria;
    return Semantics(
      button: true,
      label: '$titulo: $valor $legenda',
      excludeSemantics: true,
      child: Material(
        color: claro.withOpacity(0.14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: claro.withOpacity(0.25)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              children: [
                Text(
                  titulo,
                  style: estilos.bodySmall?.copyWith(
                    color: claro.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  child: Text(
                    valor,
                    style: estilos.titleMedium?.copyWith(color: claro),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  child: Text(
                    legenda,
                    style: estilos.labelSmall?.copyWith(
                      color: claro.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
