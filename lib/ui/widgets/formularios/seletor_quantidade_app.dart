// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:sou_consultora/ui/temas/cores_app.dart';
import 'package:sou_consultora/ui/widgets/formularios/campo_texto_app.dart';

/// Quantidade com botões − e +, respeitando [minimo] e [maximo].
/// O [rotulo] fica sobre a borda, como nos demais campos.
class SeletorQuantidadeApp extends StatelessWidget {
  const SeletorQuantidadeApp({
    super.key,
    required this.valor,
    required this.onChanged,
    this.rotulo = 'Quantidade',
    this.obrigatorio = false,
    this.minimo = 1,
    this.maximo,
  });

  final int valor;
  final ValueChanged<int> onChanged;
  final String rotulo;
  final bool obrigatorio;
  final int minimo;

  /// Sem máximo quando null (ex.: estoque não controlado).
  final int? maximo;

  bool get _podeDiminuir => valor > minimo;
  bool get _podeAumentar => maximo == null || valor < maximo!;

  void _diminuir() => onChanged(valor - 1);
  void _aumentar() => onChanged(valor + 1);

  @override
  Widget build(BuildContext context) {
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: CoresApp.primariaSuave, width: 1.5),
    );
    return InputDecorator(
      decoration: InputDecoration(
        label: RotuloCampoApp(rotulo: rotulo, obrigatorio: obrigatorio),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        // 48 do botão + 14 = mesma altura dos campos de texto. O recuo lateral
        // põe o rótulo no mesmo lugar e não come o canto da borda.
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        enabledBorder: borda,
        border: borda,
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
