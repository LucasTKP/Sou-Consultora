import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _mensagemSemConexao =
    'Sem conexão com a internet. Verifique e tente novamente.';

/// Código do Postgres para violação de unicidade.
const _codigoDuplicado = '23505';

/// Código próprio das funções do banco para erro de negócio, sempre com uma
/// mensagem em português escrita para a consultora (ex.: lote com vendas).
const _codigoNegocio = 'SC400';

/// Converte exceções de rede/Supabase em [FalhaApp] (nunca chegam à UI cruas).
///
/// [mensagemDuplicado], quando informada, vira [FalhaValidacao] se o banco
/// recusar a gravação por valor repetido (ex.: nome de fornecedor).
FalhaApp mapearFalha(
  Object erro, {
  required String mensagemPadrao,
  String? mensagemDuplicado,
}) {
  return switch (erro) {
    SocketException() ||
    TimeoutException() ||
    ClientException() ||
    AuthRetryableFetchException() => const FalhaRede(_mensagemSemConexao),
    AuthException() => FalhaAutenticacao(erro.message),
    PostgrestException(code: _codigoDuplicado) when mensagemDuplicado != null =>
      FalhaValidacao(mensagemDuplicado),
    PostgrestException(code: _codigoNegocio, :final message) => FalhaValidacao(
      message,
    ),
    _ => FalhaInesperada(mensagemPadrao),
  };
}

/// Executa [acao] e devolve [Sucesso] ou [Erro] já mapeado.
Future<Resultado<T>> executarComFalha<T>(
  Future<T> Function() acao, {
  required String mensagemPadrao,
  String? mensagemDuplicado,
}) async {
  try {
    return Sucesso(await acao());
  } catch (erro, pilha) {
    return Erro(
      mapearFalha(
        erro,
        mensagemPadrao: mensagemPadrao,
        mensagemDuplicado: mensagemDuplicado,
      ),
      causa: erro,
      pilha: pilha,
    );
  }
}
