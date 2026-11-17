// Ponte do `flutter drive` para os testes de integration_test/.
// Diferente do `flutter test`, o `flutter drive` não desinstala o app no fim
// (a sessão do Google/Apple continua salva no aparelho).
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
