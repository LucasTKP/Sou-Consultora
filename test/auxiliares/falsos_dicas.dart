import 'package:sou_consultora/core/model/dica_app.dart';
import 'package:sou_consultora/core/repository/repositorio_dicas.dart';
import 'package:sou_consultora/core/service/servico_dicas.dart';

/// Guarda em memória o que a consultora já viu.
class ServicoDicasFalso implements ServicoDicas {
  ServicoDicasFalso({Set<DicaApp>? vistas}) : vistas = vistas ?? {};

  final Set<DicaApp> vistas;
  bool falhar = false;

  @override
  Future<bool> jaViu(DicaApp dica) async {
    if (falhar) throw StateError('sem armazenamento');
    return vistas.contains(dica);
  }

  @override
  Future<void> marcarComoVista(DicaApp dica) async {
    if (falhar) throw StateError('sem armazenamento');
    vistas.add(dica);
  }
}

RepositorioDicas repositorioDicasDeTeste([ServicoDicasFalso? servico]) =>
    RepositorioDicas(servico: servico ?? ServicoDicasFalso());
