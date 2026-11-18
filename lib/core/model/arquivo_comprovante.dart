import 'dart:typed_data';

/// De onde vem o comprovante do boleto.
enum OrigemComprovante { camera, galeria, pdf }

/// Tipo do arquivo de comprovante aceito pelo bucket `comprovantes`.
enum TipoComprovante {
  jpg('jpg', 'image/jpeg'),
  png('png', 'image/png'),
  pdf('pdf', 'application/pdf');

  const TipoComprovante(this.extensao, this.tipoConteudo);

  final String extensao;
  final String tipoConteudo;

  /// Pela extensão do nome ("Comprovante.PDF" → pdf); null se não for aceito.
  static TipoComprovante? doNome(String nome) {
    final extensao = nome.split('.').last.toLowerCase();
    if (extensao == 'jpeg') return jpg;
    for (final tipo in values) {
      if (tipo.extensao == extensao) return tipo;
    }
    return null;
  }
}

/// Foto ou PDF escolhido para anexar ao boleto.
class ArquivoComprovante {
  const ArquivoComprovante({required this.bytes, required this.tipo});

  final Uint8List bytes;
  final TipoComprovante tipo;

  /// Mesmo limite do bucket `comprovantes`.
  static const limiteBytes = 10 * 1024 * 1024;

  static String? validarTamanho(int bytes) => bytes > limiteBytes
      ? 'O arquivo passa de 10 MB. Escolha um menor.'
      : null;
}
