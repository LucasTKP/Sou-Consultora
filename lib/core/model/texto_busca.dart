/// Normalização de texto para busca (sem maiúsculas nem acentos).
abstract final class TextoBusca {
  static const _comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  static const _semAcento = 'aaaaaeeeeiiiiooooouuuucn';

  /// "Patrícia  Ribeiro " → "patricia ribeiro"
  static String normalizar(String texto) {
    final minusculo = texto.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final saida = StringBuffer();
    for (final letra in minusculo.split('')) {
      final posicao = _comAcento.indexOf(letra);
      saida.write(posicao < 0 ? letra : _semAcento[posicao]);
    }
    return saida.toString();
  }

  /// [texto] contém [busca], ignorando maiúsculas e acentos. Busca vazia → true.
  static bool contem(String texto, String busca) {
    final alvo = normalizar(busca);
    return alvo.isEmpty || normalizar(texto).contains(alvo);
  }
}
