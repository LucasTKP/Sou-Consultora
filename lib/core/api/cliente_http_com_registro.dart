import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sou_consultora/core/api/registro_depuracao.dart';

/// Client HTTP que imprime cada requisição e resposta no terminal de
/// depuração. Usado pelo Supabase (auth, banco, storage) e pelo ViaCEP.
class ClienteHttpComRegistro extends http.BaseClient {
  ClienteHttpComRegistro([http.Client? interno])
    : _interno = interno ?? http.Client();

  final http.Client _interno;
  static var _proximoId = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest requisicao) async {
    if (!RegistroDepuracao.ativo) return _interno.send(requisicao);

    final id = ++_proximoId;
    final metodo = requisicao.method;
    final url = requisicao.url;

    RegistroDepuracao.requisicao(
      id,
      metodo,
      url,
      cabecalhos: requisicao.headers,
      corpo: _corpoDaRequisicao(requisicao),
    );

    final cronometro = Stopwatch()..start();
    final http.StreamedResponse resposta;
    try {
      resposta = await _interno.send(requisicao);
    } catch (erro) {
      RegistroDepuracao.falhaRequisicao(
        id,
        metodo,
        url,
        causa: erro,
        duracao: cronometro.elapsed,
      );
      rethrow;
    }

    // Lê o corpo para imprimir e devolve uma resposta nova com os mesmos bytes.
    final bytes = await resposta.stream.toBytes();
    RegistroDepuracao.resposta(
      id,
      metodo,
      url,
      status: resposta.statusCode,
      duracao: cronometro.elapsed,
      corpo: _textoOuResumo(bytes, resposta.headers['content-type']),
    );

    return http.StreamedResponse(
      http.ByteStream.fromBytes(bytes),
      resposta.statusCode,
      contentLength: bytes.length,
      request: resposta.request,
      headers: resposta.headers,
      isRedirect: resposta.isRedirect,
      persistentConnection: resposta.persistentConnection,
      reasonPhrase: resposta.reasonPhrase,
    );
  }

  @override
  void close() => _interno.close();

  static String? _corpoDaRequisicao(http.BaseRequest requisicao) {
    return switch (requisicao) {
      http.Request(:final bodyBytes, :final headers) => _textoOuResumo(
        bodyBytes,
        headers['content-type'],
      ),
      http.MultipartRequest(:final fields, :final files) =>
        'multipart campos=$fields arquivos=${files.map((f) => '${f.filename} (${f.length} bytes)').toList()}',
      _ => '(stream ${requisicao.contentLength ?? '?'} bytes)',
    };
  }

  static String? _textoOuResumo(List<int> bytes, String? tipo) {
    if (bytes.isEmpty) return null;
    final ehTexto =
        tipo == null ||
        tipo.contains('json') ||
        tipo.startsWith('text/') ||
        tipo.contains('x-www-form-urlencoded');
    if (!ehTexto) return '($tipo, ${bytes.length} bytes)';
    return utf8.decode(bytes, allowMalformed: true);
  }
}
