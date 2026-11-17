import 'dart:async';

import 'package:sou_consultora/core/dto/categoria_dto.dart';
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

  /// Guardadas por tipo (`produto` / `servico`) depois da 1ª leitura.
  final Map<String, List<Categoria>> _porTipo = {};

  Future<Resultado<List<Categoria>>> deProduto() =>
      _doTipo('produto', _servico.listarDeProduto);

  Future<Resultado<List<Categoria>>> deServico() =>
      _doTipo('servico', _servico.listarDeServico);

  /// Esquece as categorias (ao sair da conta).
  void limpar() => _porTipo.clear();

  Future<Resultado<List<Categoria>>> _doTipo(
    String tipo,
    Future<Resultado<List<CategoriaDto>>> Function() buscar,
  ) async {
    if (_porTipo[tipo] case final lista?) return Sucesso(lista);
    final resultado = await buscar();
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(
        _porTipo[tipo] = valor.map((dto) => dto.paraModel()).toList(),
      ),
    };
  }

  Future<void> encerrar() async => _assinaturaSessao?.cancel();
}
