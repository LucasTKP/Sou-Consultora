import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/produto.dart';
import 'package:sou_consultora/core/service/servico_categorias.dart';
import 'package:sou_consultora/core/service/servico_produtos.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ApiFalsa implements ApiSupabase {
  bool semRede = false;
  bool codigoRepetido = false;
  String? usuario = 'u1';
  String? tabela;
  Map<String, Object>? filtro;
  Map<String, dynamic>? dados;
  String? arquivoEnviado;
  List<String>? caminhosAssinados;

  static const _linha = {
    'id': 'p1',
    'fornecedor_id': 'm1',
    'categoria_id': 'c1',
    'nome': 'Kit Lily',
    'codigo': null,
    'preco_venda': 219.9,
    'preco_custo': null,
    'durabilidade_dias': 60,
    'observacoes': null,
    'foto_url': null,
    'created_at': '2026-11-17T12:00:00Z',
    'fornecedor_nome': 'O Boticário',
    'fornecedor_ativo': true,
    'categoria_nome': 'Perfumaria',
    'qtd_disponivel': 0,
    'validade_atual': null,
  };

  void _falhar() {
    if (semRede) throw const SocketException('offline');
    if (codigoRepetido) {
      throw const PostgrestException(message: 'duplicate', code: '23505');
    }
  }

  @override
  Future<Map<String, dynamic>> atualizar(
    String tabela,
    Map<String, dynamic> dados, {
    required String coluna,
    required Object valor,
  }) async {
    _falhar();
    return _linha;
  }

  @override
  String? get idUsuario => usuario;

  @override
  Future<List<Map<String, dynamic>>> listar(
    String tabela, {
    String? ordenarPor,
    Map<String, Object> onde = const {},
  }) async {
    _falhar();
    this.tabela = tabela;
    filtro = onde;
    if (tabela == 'categorias') {
      return [
        {'id': 'c1', 'nome': 'Perfumaria', 'tipo': 'produto'},
      ];
    }
    return [_linha];
  }

  @override
  Future<Map<String, dynamic>> inserir(
    String tabela,
    Map<String, dynamic> dados,
  ) async {
    _falhar();
    this.tabela = tabela;
    this.dados = dados;
    return {'id': 'novo'};
  }

  @override
  Future<void> enviarArquivo(
    String bucket,
    String caminho,
    Uint8List bytes, {
    required String tipoConteudo,
  }) async {
    _falhar();
    arquivoEnviado = '$bucket/$caminho';
  }

  @override
  Future<Map<String, String>> urlsAssinadas(
    String bucket,
    List<String> caminhos, {
    Duration validade = const Duration(hours: 1),
  }) async {
    caminhosAssinados = caminhos;
    return {for (final c in caminhos) c: 'https://assinada/$c'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _ApiFalsa api;
  late ServicoProdutos servico;

  setUp(() {
    api = _ApiFalsa();
    servico = ServicoProdutos(
      api: api,
      agora: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
  });

  test('lista o resumo pela view', () async {
    final resultado = await servico.listarResumos();

    expect(api.tabela, 'resumo_produtos');
    expect((resultado as Sucesso).valor.single.precoVenda, 21990);
  });

  test('sem rede vira FalhaRede', () async {
    api.semRede = true;

    final resultado = await servico.listarResumos();

    expect((resultado as Erro).falha, isA<FalhaRede>());
  });

  test('código repetido na mesma marca vira mensagem amigável', () async {
    api.codigoRepetido = true;
    final produto = Produto(
      nome: 'Kit Lily',
      fornecedorId: 'm1',
      categoriaId: 'c1',
      precoVendaCentavos: 21990,
      codigo: 'X-1',
    );

    final criar = await servico.criar(produto);
    final atualizar = await servico.atualizar('p1', produto);

    for (final resultado in [criar, atualizar]) {
      final falha = (resultado as Erro).falha;
      expect(falha, isA<FalhaValidacao>());
      expect(falha.mensagem, Produto.mensagemCodigoDuplicado);
    }
  });

  test('criar envia só as colunas do produto', () async {
    final resultado = await servico.criar(
      Produto(
        nome: 'Kit Lily',
        fornecedorId: 'm1',
        categoriaId: 'c1',
        precoVendaCentavos: 21990,
      ),
    );

    expect((resultado as Sucesso).valor, 'novo');
    expect(api.tabela, 'produtos');
    expect(api.dados!.keys, isNot(contains('consultora_id')));
    expect(api.dados!.keys, isNot(contains('id')));
    expect(api.dados!.keys, isNot(contains('created_at')));
    expect(api.dados!['preco_venda'], 219.9);
  });

  test('foto vai para a pasta de produtos da consultora', () async {
    final resultado = await servico.enviarFoto(Uint8List.fromList([1]));

    expect((resultado as Sucesso).valor, 'u1/produtos/1700000000000.jpg');
    expect(api.arquivoEnviado, 'fotos/u1/produtos/1700000000000.jpg');
  });

  test('sem sessão não envia foto', () async {
    api.usuario = null;

    final resultado = await servico.enviarFoto(Uint8List.fromList([1]));

    expect((resultado as Erro).falha, isA<FalhaAutenticacao>());
    expect(api.arquivoEnviado, isNull);
  });

  test('URLs das fotos numa chamada só', () async {
    final resultado = await servico.urlsDasFotos(['a.jpg', 'b.jpg']);

    expect(api.caminhosAssinados, ['a.jpg', 'b.jpg']);
    expect((resultado as Sucesso).valor['b.jpg'], 'https://assinada/b.jpg');
  });

  test('categorias só do tipo produto', () async {
    final resultado = await ServicoCategorias(api: api).listarDeProduto();

    expect(api.tabela, 'categorias');
    expect(api.filtro, {'tipo': 'produto'});
    expect((resultado as Sucesso).valor.single.nome, 'Perfumaria');
  });
}
