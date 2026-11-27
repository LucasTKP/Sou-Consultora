import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/api/api_supabase.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/service/servico_catalogo.dart';

class _ApiFalsa implements ApiSupabase {
  String? tabela;
  String? ordenarPor;
  int? limite;
  Map<String, Object>? onde;
  Map<String, List<String>>? contem;

  @override
  Future<List<Map<String, dynamic>>> listarComBusca(
    String tabela, {
    required String ordenarPor,
    required int limite,
    Map<String, Object> onde = const {},
    Map<String, List<String>> contem = const {},
  }) async {
    this.tabela = tabela;
    this.ordenarPor = ordenarPor;
    this.limite = limite;
    this.onde = onde;
    this.contem = contem;
    return [
      {
        'id': 'c1',
        'marca': 'Natura',
        'codigo': '174918',
        'nome': 'Balm labial cor ameixa',
        'categoria': 'Maquiagem',
        'foto_caminho': 'natura/174918.jpg',
      },
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _ApiFalsa api;
  late ServicoCatalogo servico;

  setUp(() {
    api = _ApiFalsa();
    servico = ServicoCatalogo(api: api);
  });

  test('lista da tabela do catálogo, em ordem de nome e com limite', () async {
    final resultado = await servico.listar(marca: 'Natura');

    expect(api.tabela, 'catalogo_produtos');
    expect(api.ordenarPor, 'nome');
    expect(api.limite, 60);
    expect(api.onde, {'marca': 'Natura'});
    expect((resultado as Sucesso).valor.single.codigo, '174918');
  });

  test('sem marca não filtra por marca', () async {
    await servico.listar();
    expect(api.onde, isEmpty);
  });

  test('a busca vira palavras sem acento nem maiúsculas', () async {
    await servico.listar(texto: '  Colônia   FEMININA ação ');
    expect(api.contem, {
      'busca': ['colonia', 'feminina', 'acao'],
    });
  });

  test('texto vazio não restringe a busca', () async {
    await servico.listar(texto: '   ');
    expect(api.contem, {'busca': isEmpty});
  });
}
