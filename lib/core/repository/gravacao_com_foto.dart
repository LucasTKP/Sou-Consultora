import 'dart:typed_data';

import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/mudanca_foto.dart';

/// Grava um cadastro que tem foto (produto, serviço) sem deixar arquivo órfão:
///
/// 1. com foto nova, envia antes ([enviar]);
/// 2. grava com o caminho final ([gravar]);
/// 3. se a gravação falhar, apaga a foto nova;
/// 4. se der certo, apaga a foto antiga trocada ou removida (falha nessa
///    limpeza não desfaz o salvar).
Future<Resultado<String>> gravarComFoto({
  required String? caminhoAnterior,
  required MudancaFoto foto,
  required Future<Resultado<String>> Function(Uint8List bytes) enviar,
  required Future<Resultado<void>> Function(String caminho) remover,
  required Future<Resultado<String>> Function(String? caminho) gravar,
}) async {
  final String? novoCaminho;
  switch (await _caminhoFinal(caminhoAnterior, foto, enviar)) {
    case Erro(:final falha):
      return Erro(falha);
    case Sucesso(:final valor):
      novoCaminho = valor;
  }

  final resultado = await gravar(novoCaminho);
  if (resultado is Erro<String>) {
    if (novoCaminho != null && novoCaminho != caminhoAnterior) {
      await remover(novoCaminho);
    }
    return resultado;
  }
  if (caminhoAnterior != null && caminhoAnterior != novoCaminho) {
    await remover(caminhoAnterior);
  }
  return resultado;
}

Future<Resultado<String?>> _caminhoFinal(
  String? anterior,
  MudancaFoto foto,
  Future<Resultado<String>> Function(Uint8List bytes) enviar,
) async {
  return switch (foto) {
    ManterFoto() => Sucesso(anterior),
    RemoverFoto() => const Sucesso(null),
    TrocarFoto(:final bytes) => await enviar(bytes),
  };
}
