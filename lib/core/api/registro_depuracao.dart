import 'package:flutter/foundation.dart';

/// Logs do terminal de depuração (só em debug; em release não imprime nada).
///
/// Tokens, senhas, telefone, WhatsApp, CPF e chave Pix são mascarados antes
/// de imprimir (regra 8 de `.claude/rules/seguranca.md`).
abstract final class RegistroDepuracao {
  static const _tamanhoMaximoCorpo = 4000;
  static const _tamanhoLinha = 800; // o logcat do Android corta linhas longas
  static const _framesPilha = 12;

  /// Tokens pelo nome exato; dados pessoais também com prefixo, como nas
  /// views e RPCs (`cliente_whatsapp`, `p_whatsapp`, `fornecedor_telefone`).
  static final _camposSensiveis = RegExp(
    r'"(access_token|refresh_token|id_token|provider_token|'
    r'provider_refresh_token|password|nonce|token|'
    r'[a-z0-9_]*(?:whatsapp|telefone|cpf|chave_pix))"\s*:\s*"[^"]*"',
    caseSensitive: false,
  );
  static final _tokenNaUrl = RegExp(r'([?&]token=)[^&"\s]+');
  static const _cabecalhosSensiveis = {'authorization', 'apikey', 'cookie'};

  static bool get ativo => kDebugMode;

  /// Erro que vai virar mensagem na tela (ou exceção não tratada).
  static void erro(String titulo, {Object? causa, StackTrace? pilha}) {
    if (!ativo) return;
    _imprimir('ERRO', [
      titulo,
      if (causa != null) 'causa: ${causa.runtimeType}: $causa',
      if (pilha != null) 'pilha:\n${_resumirPilha(pilha)}',
    ]);
  }

  static void requisicao(
    int id,
    String metodo,
    Uri url, {
    Map<String, String> cabecalhos = const {},
    String? corpo,
  }) {
    if (!ativo) return;
    _imprimir('HTTP #$id →', [
      '$metodo ${mascarar(url.toString())}',
      if (cabecalhos.isNotEmpty)
        'cabeçalhos: ${_mascararCabecalhos(cabecalhos)}',
      if (corpo != null && corpo.isNotEmpty)
        'corpo: ${_cortar(mascarar(corpo))}',
    ]);
  }

  static void resposta(
    int id,
    String metodo,
    Uri url, {
    required int status,
    required Duration duracao,
    String? corpo,
  }) {
    if (!ativo) return;
    final rotulo = status >= 400 ? 'HTTP #$id ✖' : 'HTTP #$id ←';
    _imprimir(rotulo, [
      '$status $metodo ${mascarar(url.path)} (${duracao.inMilliseconds} ms)',
      if (corpo != null && corpo.isNotEmpty)
        'corpo: ${_cortar(mascarar(corpo))}',
    ]);
  }

  static void falhaRequisicao(
    int id,
    String metodo,
    Uri url, {
    required Object causa,
    required Duration duracao,
  }) {
    if (!ativo) return;
    _imprimir('HTTP #$id ✖', [
      '$metodo ${mascarar(url.path)} falhou (${duracao.inMilliseconds} ms)',
      'causa: ${causa.runtimeType}: $causa',
    ]);
  }

  @visibleForTesting
  static String mascarar(String texto) => texto
      .replaceAllMapped(_camposSensiveis, (m) => '"${m[1]}":"***"')
      .replaceAllMapped(_tokenNaUrl, (m) => '${m[1]}***');

  static Map<String, String> _mascararCabecalhos(
    Map<String, String> cabecalhos,
  ) {
    return {
      for (final MapEntry(:key, :value) in cabecalhos.entries)
        key: _cabecalhosSensiveis.contains(key.toLowerCase()) ? '***' : value,
    };
  }

  static String _cortar(String texto) => texto.length <= _tamanhoMaximoCorpo
      ? texto
      : '${texto.substring(0, _tamanhoMaximoCorpo)}… (+${texto.length - _tamanhoMaximoCorpo} caracteres)';

  static String _resumirPilha(StackTrace pilha) {
    final linhas = pilha
        .toString()
        .split('\n')
        .where(
          (l) =>
              l.trim().isNotEmpty &&
              !l.contains('registro_depuracao.dart') &&
              !l.contains('erros/resultado.dart'),
        )
        .toList();
    final resumo = linhas.take(_framesPilha).join('\n');
    return linhas.length > _framesPilha ? '$resumo\n…' : resumo;
  }

  static void _imprimir(String rotulo, List<String> partes) {
    final saida = StringBuffer('┌─ [$rotulo]\n');
    for (final linha in partes.join('\n').split('\n')) {
      for (var i = 0; i < linha.length || i == 0; i += _tamanhoLinha) {
        final fim = (i + _tamanhoLinha).clamp(0, linha.length);
        saida.writeln('│ ${linha.substring(i, fim)}');
      }
    }
    saida.write('└─');
    debugPrint(saida.toString());
  }
}
