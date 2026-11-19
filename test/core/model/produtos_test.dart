import 'package:flutter_test/flutter_test.dart';
import 'package:sou_consultora/core/dto/categoria_dto.dart';
import 'package:sou_consultora/core/dto/resumo_produto_dto.dart';
import 'package:sou_consultora/core/model/durabilidade.dart';
import 'package:sou_consultora/core/model/filtro_produtos.dart';
import 'package:sou_consultora/core/model/produto.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';

ResumoProduto _resumo(
  String nome, {
  int preco = 1000,
  int qtd = 0,
  String marcaId = 'm1',
  String marca = 'Natura',
  String categoriaId = 'c1',
  String categoria = 'Perfumaria',
  String? codigo,
}) => ResumoProduto(
  id: nome,
  nome: nome,
  fornecedorId: marcaId,
  fornecedorNome: marca,
  categoriaId: categoriaId,
  categoriaNome: categoria,
  precoVenda: preco,
  criadoEm: DateTime(2026, 1, 1),
  qtdDisponivel: qtd,
  codigo: codigo,
);

void main() {
  group('Durabilidade', () {
    test('texto com meses só quando fecha em meses', () {
      expect(Durabilidade.texto(30), '30 dias (1 mês)');
      expect(Durabilidade.texto(60), '60 dias (2 meses)');
      expect(Durabilidade.texto(45), '45 dias');
      expect(Durabilidade.opcoes.first, 30);
      expect(Durabilidade.opcoes.last, 180);
    });
  });

  group('Produto', () {
    test('validações do passo 1', () {
      expect(Produto.validarNome('  '), 'Informe o nome do produto');
      expect(Produto.validarNome('Kit Lily'), isNull);
      expect(Produto.validarMarca(null), 'Escolha a marca');
      expect(Produto.validarMarca('m1'), isNull);
      expect(Produto.validarCategoria(null), 'Escolha a categoria');
    });

    test('preço de venda precisa ser maior que zero', () {
      expect(Produto.validarPrecoVenda(null), 'Informe o preço de venda');
      expect(Produto.validarPrecoVenda(0), 'Informe o preço de venda');
      expect(Produto.validarPrecoVenda(21990), isNull);
    });

    test('paraGravar: vazios viram null, centavos viram reais, durabilidade opcional', () {
      final dados = Produto(
        nome: ' Kit Lily ',
        fornecedorId: 'm1',
        categoriaId: 'c1',
        precoVendaCentavos: 21990,
        codigo: '  ',
        observacoes: '',
      ).paraGravar();
      expect(dados['nome'], 'Kit Lily');
      expect(dados['codigo'], isNull);
      expect(dados['observacoes'], isNull);
      expect(dados['preco_venda'], 219.9);
      expect(dados['preco_custo'], isNull);
      expect(dados['durabilidade_dias'], isNull);
      expect(dados['foto_url'], isNull);
      expect(dados.keys, isNot(contains('consultora_id')));
      expect(dados.keys, isNot(contains('id')));
    });
  });

  group('ResumoProduto', () {
    test('situação e texto do estoque', () {
      expect(_resumo('a').textoEstoque, 'Esgotado');
      expect(_resumo('a', qtd: 1).situacao, SituacaoEstoque.baixo);
      expect(_resumo('a', qtd: 1).textoEstoque, '1 un (baixo)');
      expect(_resumo('a', qtd: 2).situacao, SituacaoEstoque.baixo);
      expect(_resumo('a', qtd: 3).situacao, SituacaoEstoque.emEstoque);
      expect(_resumo('a', qtd: 4).textoEstoque, '4 un');
    });

    test('busca por nome, marca e código, sem acento', () {
      final kit = _resumo(
        'Kit Lily',
        marca: 'O Boticário',
        codigo: 'BOT-74892',
      );
      expect(kit.combinaBusca('boticario'), isTrue);
      expect(kit.combinaBusca('bot-748'), isTrue);
      expect(kit.combinaBusca('lily'), isTrue);
      expect(kit.combinaBusca('natura'), isFalse);
    });
  });

  group('FiltroProdutos', () {
    final produtos = [
      _resumo(
        'Batom',
        preco: 4999,
        qtd: 8,
        categoriaId: 'c2',
        categoria: 'Maquiagem',
      ),
      _resumo(
        'Kit Lily',
        preco: 24000,
        qtd: 4,
        marcaId: 'm2',
        marca: 'O Boticário',
      ),
      _resumo('Essencial', preco: 18990, qtd: 1),
      _resumo('Malbec', preco: 19990, marcaId: 'm2', marca: 'O Boticário'),
    ];

    List<String> nomes(List<ResumoProduto> lista) =>
        lista.map((p) => p.nome).toList();

    test('ordena por preço, maior ou menor', () {
      final maior = FiltroProdutos.aplicar(
        produtos,
        marcaCategoria: FiltroMarcaCategoria.todas,
        estoque: StatusFiltroEstoque.todos,
        busca: '',
        ordem: OrdemPreco.maior,
      );
      expect(nomes(maior), ['Kit Lily', 'Malbec', 'Essencial', 'Batom']);
      final menor = FiltroProdutos.aplicar(
        produtos,
        marcaCategoria: FiltroMarcaCategoria.todas,
        estoque: StatusFiltroEstoque.todos,
        busca: '',
        ordem: OrdemPreco.menor,
      );
      expect(nomes(menor), ['Batom', 'Essencial', 'Malbec', 'Kit Lily']);
      expect(OrdemPreco.maior.invertida, OrdemPreco.menor);
    });

    test('filtra por marca, categoria, estoque e busca', () {
      List<String> aplicar({
        FiltroMarcaCategoria marcaCategoria = FiltroMarcaCategoria.todas,
        StatusFiltroEstoque estoque = StatusFiltroEstoque.todos,
        String busca = '',
      }) => nomes(
        FiltroProdutos.aplicar(
          produtos,
          marcaCategoria: marcaCategoria,
          estoque: estoque,
          busca: busca,
          ordem: OrdemPreco.maior,
        ),
      );

      expect(
        aplicar(
          marcaCategoria: const FiltroMarcaCategoria.marca('m2', 'O Boticário'),
        ),
        ['Kit Lily', 'Malbec'],
      );
      expect(
        aplicar(
          marcaCategoria: const FiltroMarcaCategoria.categoria(
            'c2',
            'Maquiagem',
          ),
        ),
        ['Batom'],
      );
      expect(aplicar(estoque: StatusFiltroEstoque.baixo), ['Essencial']);
      expect(aplicar(estoque: StatusFiltroEstoque.esgotado), ['Malbec']);
      expect(aplicar(estoque: StatusFiltroEstoque.emEstoque), [
        'Kit Lily',
        'Batom',
      ]);
      expect(aplicar(busca: 'boticario'), ['Kit Lily', 'Malbec']);
    });

    test('contagens e opções de marca/categoria', () {
      final contagens = FiltroProdutos.contagens(produtos);
      expect(contagens[StatusFiltroEstoque.todos], 4);
      expect(contagens[StatusFiltroEstoque.emEstoque], 2);
      expect(contagens[StatusFiltroEstoque.baixo], 1);
      expect(contagens[StatusFiltroEstoque.esgotado], 1);

      final opcoes = FiltroProdutos.opcoesMarcaCategoria(produtos);
      expect(opcoes.map((o) => o.rotulo), [
        'Todas as marcas',
        'Natura',
        'O Boticário',
        'Maquiagem',
        'Perfumaria',
      ]);
    });
  });

  group('DTOs', () {
    test('ResumoProdutoDto aceita numeric como texto e campos nulos', () {
      final modelo = ResumoProdutoDto.fromJson({
        'id': 'p1',
        'fornecedor_id': 'm1',
        'categoria_id': 'c1',
        'nome': 'Kit Lily',
        'codigo': null,
        'preco_venda': '219.90',
        'preco_custo': 142.93,
        'durabilidade_dias': null,
        'observacoes': null,
        'foto_url': 'u1/produtos/1.jpg',
        'created_at': '2026-03-01T12:00:00+00:00',
        'fornecedor_nome': 'O Boticário',
        'fornecedor_ativo': false,
        'categoria_nome': 'Perfumaria',
        'qtd_disponivel': 4,
        'validade_atual': '2026-11-30',
      }).paraModel(urlFoto: 'https://assinada');

      expect(modelo.precoVenda, 21990);
      expect(modelo.precoCusto, 14293);
      expect(modelo.durabilidadeDias, isNull);
      expect(modelo.caminhoFoto, 'u1/produtos/1.jpg');
      expect(modelo.urlFoto, 'https://assinada');
      expect(modelo.fornecedorAtivo, isFalse);
      expect(modelo.validadeAtual, DateTime(2026, 11, 30));
      expect(modelo.qtdDisponivel, 4);
    });

    test('preço de custo nulo continua nulo', () {
      final modelo = ResumoProdutoDto.fromJson({
        'id': 'p1',
        'fornecedor_id': 'm1',
        'categoria_id': 'c1',
        'nome': 'Batom',
        'preco_venda': 49.99,
        'preco_custo': null,
        'created_at': '2026-03-01T12:00:00+00:00',
        'fornecedor_nome': 'Natura',
        'fornecedor_ativo': true,
        'categoria_nome': 'Maquiagem',
        'qtd_disponivel': 0,
        'validade_atual': null,
      }).paraModel();
      expect(modelo.precoCusto, isNull);
      expect(modelo.validadeAtual, isNull);
      expect(modelo.urlFoto, isNull);
      expect(modelo.paraProduto().precoVendaCentavos, 4999);
    });

    test('CategoriaDto', () {
      final categoria = CategoriaDto.fromJson({
        'id': 'c1',
        'nome': 'Perfumaria',
        'tipo': 'produto',
      }).paraModel();
      expect(categoria.nome, 'Perfumaria');
      expect(categoria.id, 'c1');
    });
  });
}
