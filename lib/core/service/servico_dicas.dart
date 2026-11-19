import 'package:shared_preferences/shared_preferences.dart';
import 'package:sou_consultora/core/model/dica_app.dart';

/// Guarda no aparelho quais dicas a consultora já viu.
abstract interface class ServicoDicas {
  Future<bool> jaViu(DicaApp dica);

  Future<void> marcarComoVista(DicaApp dica);
}

/// Usa o armazenamento local do aparelho. A chave inclui o id da consultora:
/// outra pessoa que entre no mesmo aparelho vê as dicas dela.
class ServicoDicasLocal implements ServicoDicas {
  ServicoDicasLocal({required this._idUsuario});

  final String? Function() _idUsuario;

  String _chave(DicaApp dica) =>
      'dica_${_idUsuario() ?? 'sem_sessao'}_${dica.chave}';

  @override
  Future<bool> jaViu(DicaApp dica) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chave(dica)) ?? false;
  }

  @override
  Future<void> marcarComoVista(DicaApp dica) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chave(dica), true);
  }
}
