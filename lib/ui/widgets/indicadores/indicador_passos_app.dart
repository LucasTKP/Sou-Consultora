// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// "Passo 1 de 2: Dados do Boleto" + porcentagem + barra de progresso.
class IndicadorPassosApp extends StatelessWidget {
  const IndicadorPassosApp({
    super.key,
    required this.passoAtual,
    required this.totalPassos,
    this.descricao,
  }) : assert(passoAtual >= 1 && passoAtual <= totalPassos);

  final int passoAtual;
  final int totalPassos;
  final String? descricao;

  double get _progresso => passoAtual / totalPassos;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    final titulo =
        'Passo $passoAtual de $totalPassos${descricao == null ? '' : ': $descricao'}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: estilos.labelMedium?.copyWith(
                  color: CoresApp.primariaEscura,
                ),
              ),
            ),
            Text(
              '${(_progresso * 100).round()}%',
              style: estilos.labelMedium?.copyWith(
                color: CoresApp.sobreSuperficieVariante,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progresso,
            minHeight: 8,
            color: CoresApp.primaria,
            backgroundColor: CoresApp.primariaSuave,
          ),
        ),
      ],
    );
  }
}
