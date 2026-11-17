import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/service/servico_autenticacao.dart';

class _ApiFalsa implements ApiSupabase {
  _ApiFalsa({this.falharSaidaGlobal = false});

  final bool falharSaidaGlobal;
  final List<bool> chamadasSair = [];

  @override
  Future<void> sair({bool somenteLocal = false}) async {
    chamadasSair.add(somenteLocal);
    if (!somenteLocal && falharSaidaGlobal) throw Exception('sem internet');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GoogleFalso implements GoogleSignIn {
  int saidas = 0;

  @override
  Future<void> initialize({String? clientId, String? serverClientId, String? nonce, String? hostedDomain}) async {}

  @override
  Future<void> signOut() async => saidas++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('sair encerra a sessão global e desconecta o Google', () async {
    final api = _ApiFalsa();
    final google = _GoogleFalso();
    final servico = ServicoAutenticacao(api: api, googleSignIn: google);

    final resultado = await servico.sair();

    expect(resultado, isA<Sucesso<void>>());
    expect(api.chamadasSair, [false]);
    expect(google.saidas, 1);
  });

  test('sem internet, sair remove ao menos a sessão do aparelho', () async {
    final api = _ApiFalsa(falharSaidaGlobal: true);
    final google = _GoogleFalso();
    final servico = ServicoAutenticacao(api: api, googleSignIn: google);

    final resultado = await servico.sair();

    expect(resultado, isA<Sucesso<void>>());
    expect(api.chamadasSair, [false, true]);
    expect(google.saidas, 1);
  });
}
