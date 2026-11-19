/// Versão do app no formato `maior.menor.correção` (ex.: `1.4.2`).
///
/// O número de build (`+7`) e sufixos (`-beta`) são ignorados na comparação.
class VersaoApp implements Comparable<VersaoApp> {
  const VersaoApp(this.maior, this.menor, this.correcao);

  final int maior;
  final int menor;
  final int correcao;

  /// Lê `1.2.3`, `1.2` ou `1` (partes faltantes valem 0). Texto inválido → null.
  static VersaoApp? tentarLer(String texto) {
    final partes = texto.trim().split(RegExp(r'[+-]')).first.split('.');
    if (partes.isEmpty || partes.length > 3) return null;
    final numeros = <int>[];
    for (final parte in partes) {
      final numero = int.tryParse(parte);
      if (numero == null || numero < 0) return null;
      numeros.add(numero);
    }
    while (numeros.length < 3) {
      numeros.add(0);
    }
    return VersaoApp(numeros[0], numeros[1], numeros[2]);
  }

  /// Verdadeiro se esta versão é mais antiga que [minima].
  bool abaixoDe(VersaoApp minima) => compareTo(minima) < 0;

  @override
  int compareTo(VersaoApp other) {
    if (maior != other.maior) return maior.compareTo(other.maior);
    if (menor != other.menor) return menor.compareTo(other.menor);
    return correcao.compareTo(other.correcao);
  }

  @override
  bool operator ==(Object other) => other is VersaoApp && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(maior, menor, correcao);

  @override
  String toString() => '$maior.$menor.$correcao';
}
