import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Porta única do app para o client Supabase.
class ApiSupabase {
  ApiSupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? Supabase.instance.client;

  final SupabaseClient _cliente;

  SupabaseClient get cliente => _cliente;

  GoTrueClient get autenticacao => _cliente.auth;

  /// Sessão salva no aparelho (null quando ninguém está logado).
  Session? get sessaoAtual => autenticacao.currentSession;

  /// Usuário da sessão atual.
  User? get usuarioAtual => autenticacao.currentUser;

  /// Eventos de entrada, saída, renovação e expiração da sessão.
  Stream<AuthState> get mudancasDeSessao => autenticacao.onAuthStateChange;

  /// Encerra a sessão. Com [somenteLocal], apenas remove a sessão do aparelho
  /// (não precisa de internet).
  Future<void> sair({bool somenteLocal = false}) {
    return autenticacao.signOut(
      scope: somenteLocal ? SignOutScope.local : SignOutScope.global,
    );
  }

  Future<AuthResponse> entrarComIdToken({
    required OAuthProvider provedor,
    required String idToken,
    String? accessToken,
    String? nonce,
  }) {
    return autenticacao.signInWithIdToken(
      provider: provedor,
      idToken: idToken,
      accessToken: accessToken,
      nonce: nonce,
    );
  }

  /// Id do usuário logado (null sem sessão).
  String? get idUsuario => usuarioAtual?.id;

  // —— Banco (PostgREST). O RLS limita tudo à consultora logada. ——

  /// Primeira linha de [tabela] onde [coluna] = [valor] (null se não houver).
  /// [selecao] permite embutir relações (ex.: `'*, enderecos(*)'`).
  Future<Map<String, dynamic>?> buscarUm(
    String tabela, {
    required String coluna,
    required Object valor,
    String selecao = '*',
  }) {
    return _cliente
        .from(tabela)
        .select(selecao)
        .eq(coluna, valor)
        .maybeSingle();
  }

  /// Todas as linhas visíveis de [tabela] (ou view), ordenadas por [ordenarPor].
  /// [onde] filtra por igualdade (ex.: `{'tipo': 'produto'}`).
  Future<List<Map<String, dynamic>>> listar(
    String tabela, {
    String? ordenarPor,
    Map<String, Object> onde = const {},
  }) {
    var consulta = _cliente.from(tabela).select();
    for (final MapEntry(:key, :value) in onde.entries) {
      consulta = consulta.eq(key, value);
    }
    return ordenarPor == null
        ? consulta
        : consulta.order(ordenarPor, ascending: true);
  }

  /// Chama a função [funcao] do banco (RPC) e devolve o retorno cru.
  Future<dynamic> rpc(String funcao, {Map<String, dynamic>? parametros}) {
    return _cliente.rpc(funcao, params: parametros);
  }

  /// Insere e devolve a linha gravada (com os valores padrão do banco).
  Future<Map<String, dynamic>> inserir(
    String tabela,
    Map<String, dynamic> dados,
  ) {
    return _cliente.from(tabela).insert(dados).select().single();
  }

  /// Atualiza a linha onde [coluna] = [valor] e devolve a linha gravada.
  Future<Map<String, dynamic>> atualizar(
    String tabela,
    Map<String, dynamic> dados, {
    required String coluna,
    required Object valor,
  }) {
    return _cliente
        .from(tabela)
        .update(dados)
        .eq(coluna, valor)
        .select()
        .single();
  }

  /// Apaga as linhas onde [coluna] = [valor] e devolve quantas foram apagadas
  /// (0 quando não existe ou o RLS esconde a linha).
  Future<int> excluir(
    String tabela, {
    required String coluna,
    required Object valor,
  }) async {
    final apagadas = await _cliente
        .from(tabela)
        .delete()
        .eq(coluna, valor)
        .select('id');
    return apagadas.length;
  }

  // —— Storage (buckets privados, pasta <id do usuário>/) ——

  Future<void> enviarArquivo(
    String bucket,
    String caminho,
    Uint8List bytes, {
    required String tipoConteudo,
  }) {
    return _cliente.storage
        .from(bucket)
        .uploadBinary(
          caminho,
          bytes,
          fileOptions: FileOptions(contentType: tipoConteudo, upsert: true),
        );
  }

  Future<void> removerArquivos(String bucket, List<String> caminhos) {
    return _cliente.storage.from(bucket).remove(caminhos);
  }

  /// URL temporária para exibir um arquivo privado.
  Future<String> urlAssinada(
    String bucket,
    String caminho, {
    Duration validade = const Duration(hours: 1),
  }) {
    return _cliente.storage
        .from(bucket)
        .createSignedUrl(caminho, validade.inSeconds);
  }

  /// URLs temporárias de vários arquivos numa chamada só (caminho → URL).
  /// Arquivos que não existem ficam de fora.
  Future<Map<String, String>> urlsAssinadas(
    String bucket,
    List<String> caminhos, {
    Duration validade = const Duration(hours: 1),
  }) async {
    if (caminhos.isEmpty) return const {};
    final resultados = await _cliente.storage
        .from(bucket)
        .createSignedUrlsResult(caminhos, validade.inSeconds);
    return {
      for (final resultado in resultados.whereType<SignedUrlSuccess>())
        resultado.path: resultado.signedUrl,
    };
  }

  /// Como [listar], mas também filtra por trechos de texto sem diferenciar
  /// maiúsculas ([contem], ex.: `{'busca': ['batom', 'matte']}`: a coluna precisa
  /// conter todos) e corta em [limite] linhas.
  Future<List<Map<String, dynamic>>> listarComBusca(
    String tabela, {
    required String ordenarPor,
    required int limite,
    Map<String, Object> onde = const {},
    Map<String, List<String>> contem = const {},
  }) {
    var consulta = _cliente.from(tabela).select();
    for (final MapEntry(:key, :value) in onde.entries) {
      consulta = consulta.eq(key, value);
    }
    for (final MapEntry(:key, value: trechos) in contem.entries) {
      for (final trecho in trechos) {
        consulta = consulta.ilike(key, '%$trecho%');
      }
    }
    return consulta.order(ordenarPor, ascending: true).limit(limite);
  }

  /// Baixa um arquivo de um bucket (as policies decidem quem pode ler).
  Future<Uint8List> baixarArquivo(String bucket, String caminho) {
    return _cliente.storage.from(bucket).download(caminho);
  }
}
