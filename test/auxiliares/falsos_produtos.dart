import 'dart:typed_data';

import 'package:sou_consultora/core/dto/categoria_dto.dart';
import 'package:sou_consultora/core/dto/resumo_produto_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/produto.dart';
import 'package:sou_consultora/core/repository/repositorio_categorias.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/core/service/servico_categorias.dart';
import 'package:sou_consultora/core/service/servico_produtos.dart';

import 'falsos_consultora.dart';

const falhaRedeProdutos = FalhaRede(
  'Sem conexão com a internet. Verifique e tente novamente.',
);

ResumoProdutoDto produtoDto(
  String id,
  String nome, {
  int precoVenda = 10000,
  int? precoCusto,
  String fornecedorId = 'm1',
  String fornecedorNome = 'Natura',
  bool fornecedorAtivo = true,
  String categoriaId = 'c1',
  String categoriaNome = 'Perfumaria',
  String? codigo,
  int? durabilidadeDias,
  String? observacoes,
  String? fotoUrl,
  int qtdDisponivel = 0,
  DateTime? validadeAtual,
}) {
  return ResumoProdutoDto(
    id: id,
    fornecedorId: fornecedorId,
    categoriaId: categoriaId,
    nome: nome,
    codigo: codigo,
    precoVenda: precoVenda,
    precoCusto: precoCusto,
    durabilidadeDias: durabilidadeDias,
    observacoes: observacoes,
    fotoUrl: fotoUrl,
    createdAt: DateTime(2026, 1, 10),
    fornecedorNome: fornecedorNome,
    fornecedorAtivo: fornecedorAtivo,
    categoriaNome: categoriaNome,
    qtdDisponivel: qtdDisponivel,
    validadeAtual: validadeAtual,
  );
}

/// Service falso em memória: guarda os produtos e registra as chamadas.
class ServicoProdutosFalso implements ServicoProdutos {
  ServicoProdutosFalso({List<ResumoProdutoDto>? resumos})
    : resumos = resumos ?? [];

  List<ResumoProdutoDto> resumos;
  bool falharRede = false;
  bool falharAoSalvar = false;
  final List<String> chamadas = [];
  final List<({String? id, Produto produto})> salvos = [];
  final List<String> fotosRemovidas = [];
  int _contador = 0;

  @override
  Future<Resultado<List<ResumoProdutoDto>>> listarResumos() async {
    chamadas.add('listar');
    return falharRede ? Erro(falhaRedeProdutos) : Sucesso(List.of(resumos));
  }

  @override
  Future<Resultado<ResumoProdutoDto?>> buscarResumo(String id) async {
    chamadas.add('resumo $id');
    if (falharRede) return Erro(falhaRedeProdutos);
    return Sucesso(resumos.where((r) => r.id == id).firstOrNull);
  }

  @override
  Future<Resultado<String>> criar(Produto produto) => _salvar(null, produto);

  @override
  Future<Resultado<String>> atualizar(String id, Produto produto) =>
      _salvar(id, produto);

  @override
  Future<Resultado<String>> enviarFoto(Uint8List bytes) async {
    chamadas.add('enviar foto');
    if (falharRede) return Erro(falhaRedeProdutos);
    return Sucesso('u1/produtos/${++_contador}.jpg');
  }

  @override
  Future<Resultado<void>> removerFoto(String caminho) async {
    fotosRemovidas.add(caminho);
    return const Sucesso(null);
  }

  @override
  Future<Resultado<Map<String, String>>> urlsDasFotos(
    List<String> caminhos,
  ) async {
    chamadas.add('urls ${caminhos.length}');
    return Sucesso({for (final c in caminhos) c: 'https://assinada/$c'});
  }

  Future<Resultado<String>> _salvar(String? id, Produto produto) async {
    chamadas.add(id == null ? 'criar' : 'atualizar $id');
    if (falharRede || falharAoSalvar) return Erro(falhaRedeProdutos);
    final novoId = id ?? 'novo-${++_contador}';
    salvos.add((id: id, produto: produto));
    resumos = [
      ...resumos.where((r) => r.id != novoId),
      produtoDto(
        novoId,
        produto.nome,
        precoVenda: produto.precoVendaCentavos,
        precoCusto: produto.precoCustoCentavos,
        fornecedorId: produto.fornecedorId,
        categoriaId: produto.categoriaId,
        codigo: produto.codigo,
        durabilidadeDias: produto.durabilidadeDias,
        observacoes: produto.observacoes,
        fotoUrl: produto.caminhoFoto,
      ),
    ];
    return Sucesso(novoId);
  }
}

class ServicoCategoriasFalso implements ServicoCategorias {
  int leituras = 0;

  @override
  Future<Resultado<List<CategoriaDto>>> listarDeProduto() async {
    leituras++;
    return const Sucesso([
      CategoriaDto(id: 'c2', nome: 'Maquiagem', tipo: 'produto'),
      CategoriaDto(id: 'c1', nome: 'Perfumaria', tipo: 'produto'),
    ]);
  }

  @override
  Future<Resultado<List<CategoriaDto>>> listarDeServico() async {
    leituras++;
    return const Sucesso([
      CategoriaDto(id: 's2', nome: 'Maquiagem', tipo: 'servico'),
      CategoriaDto(id: 's1', nome: 'Unhas', tipo: 'servico'),
    ]);
  }
}

RepositorioProdutos repositorioProdutosDeTeste(
  ServicoProdutosFalso servico, {
  FotoDispositivoFalsa? fotos,
  Stream<void>? sessaoEncerrada,
}) {
  return RepositorioProdutos(
    servico: servico,
    fotos: fotos ?? FotoDispositivoFalsa(),
    sessaoEncerrada: sessaoEncerrada,
  );
}

RepositorioCategorias repositorioCategoriasDeTeste([
  ServicoCategoriasFalso? servico,
]) => RepositorioCategorias(servico: servico ?? ServicoCategoriasFalso());
