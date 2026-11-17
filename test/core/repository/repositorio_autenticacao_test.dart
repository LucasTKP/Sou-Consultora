import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/repository/repositorio_autenticacao.dart';
import 'package:sou_consultora/core/service/servico_autenticacao.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ServicoFalso implements ServicoAutenticacao {
  _ServicoFalso({this.usuario, this.logado = false});

  final User? usuario;
  final bool logado;
  int saidas = 0;

  @override
  User? get usuarioAtual => usuario;

  @override
  bool get estaLogado => logado;

  @override
  Stream<bool> get sessaoAtiva => Stream.fromIterable([true, false]);

  @override
  Future<Resultado<void>> sair() async {
    saidas++;
    return const Sucesso(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

User _usuario(Map<String, dynamic> metadados, {String? email}) {
  return User(
    id: 'id',
    appMetadata: const {},
    userMetadata: metadados,
    aud: 'authenticated',
    email: email,
    createdAt: '2026-11-17T00:00:00Z',
  );
}

void main() {
  test('resumo usa nome e foto do Google', () {
    final repositorio = RepositorioAutenticacao(
      servico: _ServicoFalso(
        usuario: _usuario({'full_name': 'Ana Paula', 'avatar_url': 'https://foto/ana.png'}),
      ),
    );

    final resumo = repositorio.resumoDaConsultora();

    expect(resumo.nome, 'Ana Paula');
    expect(resumo.fotoUrl, 'https://foto/ana.png');
    expect(resumo.iniciais, 'AP');
  });

  test('resumo sem nome cai para o e-mail', () {
    final repositorio = RepositorioAutenticacao(
      servico: _ServicoFalso(usuario: _usuario({}, email: 'ana@email.com')),
    );

    expect(repositorio.resumoDaConsultora().nome, 'ana@email.com');
  });

  test('repassa sessão e saída do service', () async {
    final servico = _ServicoFalso(logado: true);
    final repositorio = RepositorioAutenticacao(servico: servico);

    expect(repositorio.estaLogado, isTrue);
    expect(await repositorio.sessaoAtiva.toList(), [true, false]);
    expect(await repositorio.sair(), isA<Sucesso<void>>());
    expect(servico.saidas, 1);
  });
}
