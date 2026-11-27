import 'dart:typed_data';

/// O que fazer com a foto ao salvar um cadastro (produto, serviço).
sealed class MudancaFoto {
  const MudancaFoto();
}

/// Mantém a foto que o produto já tem (ou continua sem foto).
final class ManterFoto extends MudancaFoto {
  const ManterFoto();
}

/// Troca pela foto nova (bytes já recortados).
final class TrocarFoto extends MudancaFoto {
  const TrocarFoto(this.bytes);

  final Uint8List bytes;
}

/// Tira a foto do produto.
final class RemoverFoto extends MudancaFoto {
  const RemoverFoto();
}
