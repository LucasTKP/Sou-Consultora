import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/mudanca_foto.dart';
import 'package:sou_consultora/core/model/produto.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';

import '../../auxiliares/falsos_produtos.dart';

Produto _produto({String? caminhoFoto}) => Produto(
  nome: 'Kit Lily',
  fornecedorId: 'm1',
  categoriaId: 'c1',
  precoVendaCentavos: 21990,
  caminhoFoto: caminhoFoto,
);

void main() {
  late ServicoProdutosFalso servico;
  late RepositorioProdutos repositorio;

  setUp(() {
    servico = ServicoProdutosFalso(
      resumos: [
        produtoDto('p1', 'Batom', fotoUrl: 'u1/produtos/antiga.jpg'),
        produtoDto('p2', 'Colônia'),
      ],
    );
    repositorio = repositorioProdutosDeTeste(servico);
  });

  test('carregar busca as URLs das fotos numa chamada só', () async {
    final resultado = await repositorio.carregar();

    final lista = (resultado as Sucesso<List<ResumoProduto>>).valor;
    expect(servico.chamadas, ['listar', 'urls 1']);
    expect(lista.first.urlFoto, 'https://assinada/u1/produtos/antiga.jpg');
    expect(lista.last.urlFoto, isNull);
  });

  test('salvar com foto nova grava o caminho novo e apaga a antiga', () async {
    final emitidas = <List<ResumoProduto>>[];
    final assinatura = repositorio.mudancas.listen(emitidas.add);

    final resultado = await repositorio.salvar(
      _produto(caminhoFoto: 'u1/produtos/antiga.jpg'),
      id: 'p1',
      foto: TrocarFoto(Uint8List.fromList([1])),
    );

    expect(resultado, isA<Sucesso<String>>());
    expect(servico.salvos.single.produto.caminhoFoto, 'u1/produtos/1.jpg');
    expect(servico.fotosRemovidas, ['u1/produtos/antiga.jpg']);
    await Future<void>.delayed(Duration.zero);
    expect(emitidas, isNotEmpty);
    await assinatura.cancel();
  });

  test('falha ao gravar apaga a foto enviada e mantém o cache', () async {
    await repositorio.carregar();
    final antes = repositorio.lista;
    servico.falharAoSalvar = true;

    final resultado = await repositorio.salvar(
      _produto(),
      foto: TrocarFoto(Uint8List.fromList([1])),
    );

    expect(resultado, isA<Erro<String>>());
    expect(servico.fotosRemovidas, ['u1/produtos/1.jpg']);
    expect(repositorio.lista, same(antes));
  });

  test('remover a foto grava null e apaga o arquivo', () async {
    await repositorio.salvar(
      _produto(caminhoFoto: 'u1/produtos/antiga.jpg'),
      id: 'p1',
      foto: const RemoverFoto(),
    );

    expect(servico.salvos.single.produto.caminhoFoto, isNull);
    expect(servico.fotosRemovidas, ['u1/produtos/antiga.jpg']);
  });

  test('manter a foto não envia nem apaga nada', () async {
    await repositorio.salvar(
      _produto(caminhoFoto: 'u1/produtos/antiga.jpg'),
      id: 'p1',
    );

    expect(servico.chamadas, isNot(contains('enviar foto')));
    expect(servico.fotosRemovidas, isEmpty);
    expect(servico.salvos.single.produto.caminhoFoto, 'u1/produtos/antiga.jpg');
  });

  test('sessão encerrada limpa o cache', () async {
    final sessao = StreamController<void>();
    repositorio = repositorioProdutosDeTeste(
      servico,
      sessaoEncerrada: sessao.stream,
    );
    await repositorio.carregar();

    sessao.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(repositorio.lista, isNull);
    await sessao.close();
  });

  test('categorias são lidas uma vez e guardadas', () async {
    final servicoCategorias = ServicoCategoriasFalso();
    final categorias = repositorioCategoriasDeTeste(servicoCategorias);

    await categorias.deProduto();
    final resultado = await categorias.deProduto();

    expect(servicoCategorias.leituras, 1);
    expect((resultado as Sucesso).valor.length, 2);
  });
}
