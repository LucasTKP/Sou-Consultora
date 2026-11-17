import 'package:sou_consultora/core/model/produto.dart';
import 'package:sou_consultora/core/model/texto_busca.dart';

/// Situação do estoque: 0 → esgotado; 1 ou 2 → baixo; 3 ou mais → em estoque.
enum SituacaoEstoque { esgotado, baixo, emEstoque }

/// Produto com marca, categoria e estoque da view `resumo_produtos`.
/// Valores em centavos.
class ResumoProduto {
  const ResumoProduto({
    required this.id,
    required this.nome,
    required this.fornecedorId,
    required this.fornecedorNome,
    required this.categoriaId,
    required this.categoriaNome,
    required this.precoVenda,
    required this.criadoEm,
    this.fornecedorAtivo = true,
    this.codigo,
    this.precoCusto,
    this.durabilidadeDias,
    this.observacoes,
    this.caminhoFoto,
    this.urlFoto,
    this.qtdDisponivel = 0,
    this.validadeAtual,
  });

  static const limiteBaixo = 2;

  final String id;
  final String nome;
  final String fornecedorId;
  final String fornecedorNome;
  final bool fornecedorAtivo;
  final String categoriaId;
  final String categoriaNome;
  final String? codigo;
  final int precoVenda;
  final int? precoCusto;
  final int? durabilidadeDias;
  final String? observacoes;

  /// Caminho no bucket (gravado no banco).
  final String? caminhoFoto;

  /// URL assinada para exibir a foto (temporária).
  final String? urlFoto;
  final DateTime criadoEm;

  /// Soma do disponível nos lotes.
  final int qtdDisponivel;

  /// Menor validade entre os lotes com unidades.
  final DateTime? validadeAtual;

  SituacaoEstoque get situacao {
    if (qtdDisponivel <= 0) return SituacaoEstoque.esgotado;
    if (qtdDisponivel <= limiteBaixo) return SituacaoEstoque.baixo;
    return SituacaoEstoque.emEstoque;
  }

  /// "Esgotado", "1 un (Baixo estoque)", "4 un em estoque".
  String get textoEstoque => switch (situacao) {
    SituacaoEstoque.esgotado => 'Esgotado',
    SituacaoEstoque.baixo => '$qtdDisponivel un (Baixo estoque)',
    SituacaoEstoque.emEstoque => '$qtdDisponivel un em estoque',
  };

  /// Busca por nome, marca ou código, sem maiúsculas nem acentos.
  bool combinaBusca(String busca) =>
      TextoBusca.contem(nome, busca) ||
      TextoBusca.contem(fornecedorNome, busca) ||
      (codigo != null && TextoBusca.contem(codigo!, busca));

  /// Dados editáveis, para abrir o formulário de edição.
  Produto paraProduto() => Produto(
    nome: nome,
    fornecedorId: fornecedorId,
    categoriaId: categoriaId,
    precoVendaCentavos: precoVenda,
    codigo: codigo,
    precoCustoCentavos: precoCusto,
    durabilidadeDias: durabilidadeDias,
    observacoes: observacoes,
    caminhoFoto: caminhoFoto,
  );
}
