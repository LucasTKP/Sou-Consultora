import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/arquivo_comprovante.dart';

/// Escolhe o comprovante: foto (câmera ou galeria, sem recorte, para não
/// cortar o papel) ou PDF.
abstract interface class ServicoEscolherComprovante {
  /// Sucesso(null) quando a pessoa desiste.
  Future<Resultado<ArquivoComprovante?>> escolher(OrigemComprovante origem);
}

class ServicoEscolherComprovanteNativo implements ServicoEscolherComprovante {
  ServicoEscolherComprovanteNativo({ImagePicker? seletor})
    : _seletor = seletor ?? ImagePicker();

  final ImagePicker _seletor;

  static const _falhaFoto = FalhaInesperada(
    'Não foi possível abrir a câmera ou a galeria. Verifique as permissões do app.',
  );
  static const _falhaPdf = FalhaInesperada('Não foi possível abrir o PDF.');

  @override
  Future<Resultado<ArquivoComprovante?>> escolher(OrigemComprovante origem) =>
      origem == OrigemComprovante.pdf ? _pdf() : _foto(origem);

  Future<Resultado<ArquivoComprovante?>> _foto(OrigemComprovante origem) async {
    try {
      final foto = await _seletor.pickImage(
        source: origem == OrigemComprovante.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 80,
      );
      if (foto == null) return const Sucesso(null);
      return Sucesso(
        ArquivoComprovante(
          bytes: await foto.readAsBytes(),
          // O image_picker devolve JPEG ao comprimir; PNG da galeria fica PNG.
          tipo: TipoComprovante.doNome(foto.name) ?? TipoComprovante.jpg,
        ),
      );
    } catch (erro, pilha) {
      return Erro(_falhaFoto, causa: erro, pilha: pilha);
    }
  }

  Future<Resultado<ArquivoComprovante?>> _pdf() async {
    try {
      final arquivo = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (arquivo == null) return const Sucesso(null);
      // Confere o tamanho antes de ler tudo para a memória.
      final tamanho = await arquivo.length() ?? 0;
      final excesso = ArquivoComprovante.validarTamanho(tamanho);
      if (excesso != null) return Erro(FalhaValidacao(excesso));
      return Sucesso(
        ArquivoComprovante(
          bytes: await arquivo.readAsBytes(),
          tipo: TipoComprovante.pdf,
        ),
      );
    } catch (erro, pilha) {
      return Erro(_falhaPdf, causa: erro, pilha: pilha);
    }
  }
}
