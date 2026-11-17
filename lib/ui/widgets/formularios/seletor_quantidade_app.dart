// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';

/// Quantidade com botões − e +, respeitando [minimo] e [maximo].
class SeletorQuantidadeApp extends StatelessWidget {
  const SeletorQuantidadeApp({
    super.key,
    required this.valor,
    required this.onChanged,
    this.minimo = 1,
    this.maximo,
  });

  final int valor;
  final ValueChanged<int> onChanged;
  final int minimo;

  /// Sem máximo quando null (ex.: estoque não controlado).
  final int? maximo;

  bool get _podeDiminuir => valor > minimo;
  bool get _podeAumentar => maximo == null || valor < maximo!;

  void _diminuir() => onChanged(valor - 1);
  void _aumentar() => onChanged(valor + 1);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoresApp.primariaSuave, width: 1.5),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Diminuir',
            onPressed: _podeDiminuir ? _diminuir : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Expanded(
            child: Text(
              '$valor',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            tooltip: 'Aumentar',
            color: CoresApp.primaria,
            onPressed: _podeAumentar ? _aumentar : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
