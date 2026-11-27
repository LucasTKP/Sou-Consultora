import 'package:flutter/widgets.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/model/dica_app.dart';
import 'package:sou_consultora/core/repository/repositorio_dicas.dart';

/// Controla o passo a passo de uma [dica]: só começa se a consultora ainda não
/// viu e, ao terminar ou ser dispensado, lembra que já foi visto.
///
/// Crie no `initState` da tela e chame [encerrar] no `dispose`.
class RoteiroDicas {
  RoteiroDicas(this.dica, {RepositorioDicas? repositorio})
    : _repositorio =
          repositorio ??
          (injetor.isRegistered<RepositorioDicas>()
              ? injetor<RepositorioDicas>()
              : null) {
    _visao = ShowcaseView.register(
      scope: dica.chave,
      onFinish: _concluir,
      onDismiss: (_) => _concluir(),
    );
  }

  final DicaApp dica;

  /// Nulo (app sem o repositório registrado, como nos testes) = nunca mostra.
  final RepositorioDicas? _repositorio;
  late final ShowcaseView _visao;
  bool _iniciado = false;

  /// Mostra os passos destacando as [chaves], na ordem, se a dica ainda não foi
  /// vista. [montado] diz se a tela ainda existe quando chegar a hora.
  Future<void> iniciar(List<GlobalKey> chaves, bool Function() montado) async {
    final repositorio = _repositorio;
    if (repositorio == null || _iniciado) return;
    _iniciado = true;
    if (!await repositorio.deveMostrar(dica)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (montado()) _visao.startShowCase(chaves);
    });
  }

  void _concluir() => _repositorio?.marcarComoVista(dica);

  void encerrar() => _visao.unregister();
}
