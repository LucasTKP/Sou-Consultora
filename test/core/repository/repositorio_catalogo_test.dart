import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/produto_catalogo.dart';

import '../../auxiliares/falsos_catalogo.dart';

List<ProdutoCatalogo> _itens(Resultado<List<ProdutoCatalogo>> r) =>
    (r as Sucesso<List<ProdutoCatalogo>>).valor;

void main() {
  late ServicoCatalogoFalso servico;

  setUp(() {
    servico = ServicoCatalogoFalso(
      itens: [
        catalogoDto('1', 'Balm labial ameixa'),
        catalogoDto('2', 'Sabonete Ekos', categoria: 'Corpo e banho'),
        catalogoDto('3', 'Batom Avon', marca: 'Avon', foto: 'avon/3.jpg'),
      ],
    );
  });

  test('busca por marca e por nome, com URL assinada da foto', () async {
    final repositorio = repositorioCatalogoDeTeste(servico);

    final todos = _itens(await repositorio.buscar());
    expect(todos.map((p) => p.codigo), ['1', '2', '3']);
    expect(todos.first.urlFoto, 'https://assinada/natura/1.jpg');

    final natura = _itens(await repositorio.buscar(marca: 'Natura'));
    expect(natura.map((p) => p.codigo), ['1', '2']);

    final sabonete = _itens(await repositorio.buscar(texto: 'SABONETE'));
    expect(sabonete.map((p) => p.codigo), ['2']);
  });

  test('a busca ignora caracteres especiais do filtro', () async {
    await repositorioCatalogoDeTeste(servico).buscar(texto: '  100%_(a),* ');
    expect(servico.buscas.last.texto, '100 a');
  });

  test('falha ao gerar as URLs não derruba a lista', () async {
    servico.falharUrls = true;
    final itens = _itens(await repositorioCatalogoDeTeste(servico).buscar());
    expect(itens, hasLength(3));
    expect(itens.every((p) => p.urlFoto == null), isTrue);
  });

  test('falha ao listar devolve erro', () async {
    servico.falharListar = true;
    expect(
      await repositorioCatalogoDeTeste(servico).buscar(),
      isA<Erro<List<ProdutoCatalogo>>>(),
    );
  });

  test('baixa a foto do produto; sem foto devolve null', () async {
    final repositorio = repositorioCatalogoDeTeste(servico);
    final comFoto = _itens(await repositorio.buscar()).first;
    final bytes = await repositorio.baixarFoto(comFoto);
    expect((bytes as Sucesso).valor, servico.bytesDaFoto);
    expect(servico.fotosBaixadas, ['natura/1.jpg']);

    const semFoto = ProdutoCatalogo(
      id: 'x',
      marca: 'Natura',
      codigo: '9',
      nome: 'Sem foto',
    );
    expect((await repositorio.baixarFoto(semFoto) as Sucesso).valor, isNull);
  });
}
