import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

/// O pacote guarda o toast num singleton. Sem isso, o teste seguinte reusa a
/// camada que o teste anterior já desmontou, e o aviso não aparece.
class _Binding extends AutomatedTestWidgetsFlutterBinding {
  @override
  void postTest() {
    for (final gerente in toastification.managers.values) {
      for (final item in gerente.notifications.toList()) {
        item.stop();
      }
      gerente.notifications.clear();
      final camada = gerente.overlayEntry;
      if (camada != null && camada.mounted) {
        camada.remove();
      }
      gerente.overlayEntry = null;
    }
    toastification.managers.clear();
    super.postTest();
  }
}

/// Carrega a Geist (fonte do shadcn_ui, que vem no pacote) antes dos testes.
/// Sem ela, o texto sai em Ahem, onde cada letra ocupa o tamanho inteiro da
/// fonte (~2x mais larga que no celular). Ver `montar_app.dart`.
/// Se o arquivo não existir, segue com a fonte padrão do Flutter.
Future<void> _carregarFontes() async {
  final geist = await _arquivoDoPacote('shadcn_ui', 'fonts/Geist[wght].ttf');
  await _carregar('packages/shadcn_ui/Geist', geist);
}

/// Arquivo dentro da raiz de um pacote (ex.: `fonts/` do shadcn_ui), lido do
/// `.dart_tool/package_config.json` que o próprio pub mantém.
Future<File?> _arquivoDoPacote(String pacote, String caminho) async {
  final config = File('.dart_tool/package_config.json');
  if (!config.existsSync()) return null;
  final json = jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;
  final pacotes = (json['packages'] as List).cast<Map<String, dynamic>>();
  final entrada = pacotes.where((p) => p['name'] == pacote).firstOrNull;
  final rootUri = entrada?['rootUri'] as String?;
  if (rootUri == null) return null;
  final raiz = config.absolute.uri.resolve(rootUri).toFilePath();
  return File('${raiz.replaceAll(RegExp(r'/$'), '')}/$caminho');
}

Future<void> _carregar(String familia, File? arquivo) async {
  if (arquivo == null || !arquivo.existsSync()) return;
  final bytes = Uint8List.fromList(arquivo.readAsBytesSync());
  final loader = FontLoader(familia)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

Future<void> testExecutable(Future<void> Function() testMain) async {
  _Binding();
  await _carregarFontes();
  await testMain();
}
