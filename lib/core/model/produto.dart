/// Dados editáveis de um produto, já normalizados para gravar:
/// textos opcionais vazios viram `null`. Valores em centavos.
class Produto {
  Produto({
    required String nome,
    required this.fornecedorId,
    required this.categoriaId,
    required this.precoVendaCentavos,
    String? codigo,
    this.precoCustoCentavos,
    this.durabilidadeDias,
    String? observacoes,
    this.caminhoFoto,
  }) : nome = nome.trim(),
       codigo = _textoOuNulo(codigo),
       observacoes = _textoOuNulo(observacoes);

  final String nome;
  final String fornecedorId;
  final String categoriaId;
  final String? codigo;
  final int precoVendaCentavos;
  final int? precoCustoCentavos;

  /// 30 a 180 dias, ou `null` (sem previsão).
  final int? durabilidadeDias;
  final String? observacoes;

  /// Caminho no bucket `fotos` (`<id>/produtos/<momento>.jpg`) ou `null`.
  final String? caminhoFoto;

  /// Colunas de `produtos` (sem `id`, `consultora_id` nem `created_at`).
  Map<String, dynamic> paraGravar() => {
    'nome': nome,
    'fornecedor_id': fornecedorId,
    'categoria_id': categoriaId,
    'codigo': codigo,
    'preco_venda': precoVendaCentavos / 100,
    'preco_custo': precoCustoCentavos == null
        ? null
        : precoCustoCentavos! / 100,
    'durabilidade_dias': durabilidadeDias,
    'observacoes': observacoes,
    'foto_url': caminhoFoto,
  };

  // —— Validações do passo 1 ——

  static String? validarNome(String texto) =>
      texto.trim().isEmpty ? 'Informe o nome do produto' : null;

  static String? validarMarca(String? fornecedorId) =>
      fornecedorId == null ? 'Escolha a marca' : null;

  static String? validarCategoria(String? categoriaId) =>
      categoriaId == null ? 'Escolha a categoria' : null;

  // —— Validações do passo 2 ——

  static String? validarPrecoVenda(int? centavos) =>
      centavos == null || centavos <= 0 ? 'Informe o preço de venda' : null;

  static String? _textoOuNulo(String? texto) {
    final limpo = texto?.trim() ?? '';
    return limpo.isEmpty ? null : limpo;
  }
}
