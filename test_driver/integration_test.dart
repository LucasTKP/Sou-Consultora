// Ponte do `flutter drive` para os testes de integration_test/.
// Diferente do `flutter test`, o `flutter drive` não desinstala o app no fim
// (a sessão do Google/Apple continua salva no aparelho).
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Os prints pedidos pelos cenários (`binding.takeScreenshot`) vão para
/// `build/prints_e2e/<nome>.png`.
Future<void> main() => integrationDriver(
  onScreenshot: (nome, bytes, [argumentos]) async {
    final arquivo = File('build/prints_e2e/$nome.png');
    await arquivo.parent.create(recursive: true);
    await arquivo.writeAsBytes(bytes);
    return true;
  },
);
