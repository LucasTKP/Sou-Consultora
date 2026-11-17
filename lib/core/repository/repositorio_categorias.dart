import 'dart:async';

import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/categoria.dart';
import 'package:sou_consultora/core/service/servico_categorias.dart';

/// Categorias de produto da consultora logada (guardadas depois da 1ª leitura).
class RepositorioCategorias {
  RepositorioCategorias({
    required this._servico,
    Stream<void>? sessaoEncerrada,
  }) {
    _assinaturaSessao = sessaoEncerrada?.listen((_) => limpar());
  }

  final ServicoCategorias _servico;
  StreamSubscription<void>? _assinaturaSessao;

  List<Categoria>? _deProduto;

  Future<Resultado<List<Categoria>>> deProduto() async {
    if (_deProduto case final lista?) return Sucesso(lista);
    final resultado = await _servico.listarDeProduto();
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(
        _deProduto = valor.map((dto) => dto.paraModel()).toList(),
      ),
    };
  }

  /// Esquece as categorias (ao sair da conta).
  void limpar() => _deProduto = null;

  Future<void> encerrar() async => _assinaturaSessao?.cancel();
}
