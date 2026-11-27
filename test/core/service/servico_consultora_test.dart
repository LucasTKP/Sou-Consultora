import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/service/servico_consultora.dart';

class _ApiFalsa implements ApiSupabase {
  _ApiFalsa({this.id = 'id-ana', this.erro});

  final String? id;
  final Object? erro;
  final List<String> chamadas = [];

  static final _linha = {
    'id': 'id-ana',
    'nome': 'Ana',
    'whatsapp': '11987654321',
    'foto_url': null,
    'chave_pix': null,
    'tipo_chave_pix': null,
    'ultimo_codigo_venda': 0,
    'created_at': '2026-11-17T10:00:00.000Z',
  };

  void _talvezFalhar() {
    if (erro != null) throw erro!;
  }

  @override
  String? get idUsuario => id;

  @override
  Future<Map<String, dynamic>?> buscarUm(
    String tabela, {
    required String coluna,
    required Object valor,
    String selecao = '*',
  }) async {
    _talvezFalhar();
    chamadas.add('buscarUm $tabela $coluna=$valor');
    return null;
  }

  @override
  Future<Map<String, dynamic>> inserir(
    String tabela,
    Map<String, dynamic> dados,
  ) async {
    _talvezFalhar();
    chamadas.add('inserir $tabela ${dados.keys.toList()}');
    return {..._linha, ...dados};
  }

  @override
  Future<Map<String, dynamic>> atualizar(
    String tabela,
    Map<String, dynamic> dados, {
    required String coluna,
    required Object valor,
  }) async {
    _talvezFalhar();
    chamadas.add('atualizar $tabela $coluna=$valor');
    return {..._linha, ...dados};
  }

  @override
  Future<void> enviarArquivo(
    String bucket,
    String caminho,
    Uint8List bytes, {
    required String tipoConteudo,
  }) async {
    _talvezFalhar();
    chamadas.add('enviar $bucket $caminho $tipoConteudo');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('sem cadastro devolve Sucesso(null)', () async {
    final api = _ApiFalsa();
    final resultado = await ServicoConsultora(api: api).buscarMinha();
    expect(resultado, isA<Sucesso>());
    expect((resultado as Sucesso).valor, isNull);
    expect(api.chamadas, ['buscarUm consultoras id=id-ana']);
  });

  test('criar não envia o id (o banco usa o usuário logado)', () async {
    final api = _ApiFalsa();
    final resultado = await ServicoConsultora(
      api: api,
    ).criar(nome: 'Ana', whatsapp: '11987654321', termosVersao: '2026-11-26');
    expect(resultado, isA<Sucesso>());
    expect(api.chamadas, [
      'inserir consultoras [nome, whatsapp, termos_versao]',
    ]);
  });

  test('foto vai para a pasta do usuário com nome novo', () async {
    final api = _ApiFalsa();
    final servico = ServicoConsultora(
      api: api,
      agora: () => DateTime.fromMillisecondsSinceEpoch(42),
    );
    final resultado = await servico.enviarFoto(Uint8List(1));
    expect((resultado as Sucesso<String>).valor, 'id-ana/perfil-42.jpg');
    expect(api.chamadas, ['enviar fotos id-ana/perfil-42.jpg image/jpeg']);
  });

  test('falha de rede vira FalhaRede com mensagem amigável', () async {
    final servico = ServicoConsultora(
      api: _ApiFalsa(erro: const SocketException('offline')),
    );
    final resultado = await servico.atualizar(
      nome: 'Ana',
      whatsapp: '11987654321',
      chavePix: null,
      tipoChavePix: null,
    );
    final falha = (resultado as Erro).falha;
    expect(falha, isA<FalhaRede>());
    expect(falha.mensagem, contains('internet'));
  });

  test(
    'erro desconhecido vira FalhaInesperada sem detalhes técnicos',
    () async {
      final servico = ServicoConsultora(
        api: _ApiFalsa(erro: StateError('detalhe interno')),
      );
      final resultado = await servico.criar(
        nome: 'Ana',
        whatsapp: '11987654321',
        termosVersao: '2026-11-26',
      );
      final falha = (resultado as Erro).falha;
      expect(falha, isA<FalhaInesperada>());
      expect(falha.mensagem, 'Não foi possível concluir o cadastro.');
    },
  );

  test('sem sessão não chama o banco', () async {
    final api = _ApiFalsa(id: null);
    final resultado = await ServicoConsultora(api: api).buscarMinha();
    expect((resultado as Erro).falha, isA<FalhaAutenticacao>());
    expect(api.chamadas, isEmpty);
  });
}
