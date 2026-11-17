import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _mensagemSemConexao = 'Sem conexão com a internet. Verifique e tente novamente.';

/// Converte exceções de rede/Supabase em [FalhaApp] (nunca chegam à UI cruas).
FalhaApp mapearFalha(Object erro, {required String mensagemPadrao}) {
  return switch (erro) {
    SocketException() || TimeoutException() || ClientException() || AuthRetryableFetchException() =>
      const FalhaRede(_mensagemSemConexao),
    AuthException() => FalhaAutenticacao(erro.message),
    _ => FalhaInesperada(mensagemPadrao),
  };
}

/// Executa [acao] e devolve [Sucesso] ou [Erro] já mapeado.
Future<Resultado<T>> executarComFalha<T>(Future<T> Function() acao, {required String mensagemPadrao}) async {
  try {
    return Sucesso(await acao());
  } catch (erro) {
    return Erro(mapearFalha(erro, mensagemPadrao: mensagemPadrao));
  }
}
