import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/env/ambiente_app.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Autenticação social via providers nativos + Supabase Auth.
class ServicoAutenticacao {
  ServicoAutenticacao({required this._api, GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final ApiSupabase _api;
  final GoogleSignIn _googleSignIn;

  static const _escopos = ['email', 'profile'];

  bool _googleInicializado = false;

  Future<Resultado<AuthResponse>> entrarComGoogle() async {
    try {
      await _garantirGoogleInicializado();

      final conta =
          await _googleSignIn.attemptLightweightAuthentication() ??
          await _googleSignIn.authenticate(scopeHint: _escopos);

      final autorizacao =
          await conta.authorizationClient.authorizationForScopes(_escopos) ??
          await conta.authorizationClient.authorizeScopes(_escopos);

      final idToken = conta.authentication.idToken;
      if (idToken == null) {
        return Erro(const FalhaAutenticacao('Token do Google não encontrado.'));
      }

      final resposta = await _api.entrarComIdToken(
        provedor: OAuthProvider.google,
        idToken: idToken,
        accessToken: autorizacao.accessToken,
      );
      return Sucesso(resposta);
    } on GoogleSignInException catch (erro, pilha) {
      if (erro.code == GoogleSignInExceptionCode.canceled) {
        return Erro(
          const FalhaAutenticacao('Login com Google cancelado.'),
          causa: erro,
          pilha: pilha,
        );
      }
      return Erro(
        const FalhaAutenticacao('Não foi possível continuar com Google.'),
        causa: erro,
        pilha: pilha,
      );
    } on AuthException catch (erro, pilha) {
      return Erro(FalhaAutenticacao(erro.message), causa: erro, pilha: pilha);
    } catch (erro, pilha) {
      return Erro(
        const FalhaInesperada('Não foi possível continuar com Google.'),
        causa: erro,
        pilha: pilha,
      );
    }
  }

  Future<Resultado<AuthResponse>> entrarComApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      return Erro(
        const FalhaAutenticacao(
          'Login com Apple nativo está disponível apenas no iPhone/iPad.',
        ),
      );
    }

    try {
      final nonceBruto = _api.autenticacao.generateRawNonce();
      final nonceHash = sha256.convert(utf8.encode(nonceBruto)).toString();

      final credencial = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonceHash,
      );

      final idToken = credencial.identityToken;
      if (idToken == null) {
        return Erro(const FalhaAutenticacao('Token da Apple não encontrado.'));
      }

      final resposta = await _api.entrarComIdToken(
        provedor: OAuthProvider.apple,
        idToken: idToken,
        nonce: nonceBruto,
      );

      await _salvarNomeAppleSePresente(credencial);

      return Sucesso(resposta);
    } on SignInWithAppleAuthorizationException catch (erro, pilha) {
      if (erro.code == AuthorizationErrorCode.canceled) {
        return Erro(
          const FalhaAutenticacao('Login com Apple cancelado.'),
          causa: erro,
          pilha: pilha,
        );
      }
      return Erro(
        const FalhaAutenticacao('Não foi possível continuar com Apple.'),
        causa: erro,
        pilha: pilha,
      );
    } on AuthException catch (erro, pilha) {
      return Erro(FalhaAutenticacao(erro.message), causa: erro, pilha: pilha);
    } catch (erro, pilha) {
      return Erro(
        const FalhaInesperada('Não foi possível continuar com Apple.'),
        causa: erro,
        pilha: pilha,
      );
    }
  }

  /// Encerra a sessão no Supabase e desconecta a conta Google do app.
  ///
  /// Se a saída global falhar (ex.: sem internet), remove ao menos a sessão
  /// do aparelho — a consultora sempre consegue sair.
  Future<Resultado<void>> sair() async {
    await _sairDoSupabase();
    await _sairDoGoogle();
    return const Sucesso(null);
  }

  /// Sessão ativa no aparelho.
  bool get estaLogado => _api.sessaoAtual != null;

  /// Emite `true`/`false` a cada mudança de sessão.
  Stream<bool> get sessaoAtiva =>
      _api.mudancasDeSessao.map((estado) => estado.session != null);

  /// Usuário logado (para montar o resumo da consultora).
  User? get usuarioAtual => _api.usuarioAtual;

  Future<void> _sairDoSupabase() async {
    try {
      await _api.sair();
    } catch (_) {
      await _api.sair(somenteLocal: true);
    }
  }

  Future<void> _sairDoGoogle() async {
    try {
      await _garantirGoogleInicializado();
      await _googleSignIn.signOut();
    } catch (_) {
      // Sem conta Google conectada (ex.: entrou com Apple): nada a desfazer.
    }
  }

  Future<void> _salvarNomeAppleSePresente(
    AuthorizationCredentialAppleID credencial,
  ) async {
    final nome = [
      credencial.givenName,
      credencial.familyName,
    ].whereType<String>().where((parte) => parte.trim().isNotEmpty).join(' ');

    if (nome.isEmpty) return;

    await _api.autenticacao.updateUser(
      UserAttributes(
        data: {
          'full_name': nome,
          'given_name': credencial.givenName,
          'family_name': credencial.familyName,
        },
      ),
    );
  }

  Future<void> _garantirGoogleInicializado() async {
    if (_googleInicializado) return;

    await _googleSignIn.initialize(
      serverClientId: AmbienteApp.idClienteGoogleWeb,
      clientId: Platform.isIOS ? AmbienteApp.idClienteGoogleIos : null,
    );
    _googleInicializado = true;
  }
}
