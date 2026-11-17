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
    return autenticacao.signOut(scope: somenteLocal ? SignOutScope.local : SignOutScope.global);
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
  Future<Map<String, dynamic>?> buscarUm(String tabela, {required String coluna, required Object valor}) {
    return _cliente.from(tabela).select().eq(coluna, valor).maybeSingle();
  }

  /// Insere e devolve a linha gravada (com os valores padrão do banco).
  Future<Map<String, dynamic>> inserir(String tabela, Map<String, dynamic> dados) {
    return _cliente.from(tabela).insert(dados).select().single();
  }

  /// Atualiza a linha onde [coluna] = [valor] e devolve a linha gravada.
  Future<Map<String, dynamic>> atualizar(
    String tabela,
    Map<String, dynamic> dados, {
    required String coluna,
    required Object valor,
  }) {
    return _cliente.from(tabela).update(dados).eq(coluna, valor).select().single();
  }

  // —— Storage (buckets privados, pasta <id do usuário>/) ——

  Future<void> enviarArquivo(String bucket, String caminho, Uint8List bytes, {required String tipoConteudo}) {
    return _cliente.storage.from(bucket).uploadBinary(
          caminho,
          bytes,
          fileOptions: FileOptions(contentType: tipoConteudo, upsert: true),
        );
  }

  Future<void> removerArquivos(String bucket, List<String> caminhos) {
    return _cliente.storage.from(bucket).remove(caminhos);
  }

  /// URL temporária para exibir um arquivo privado.
  Future<String> urlAssinada(String bucket, String caminho, {Duration validade = const Duration(hours: 1)}) {
    return _cliente.storage.from(bucket).createSignedUrl(caminho, validade.inSeconds);
  }
}
