/// Dados editáveis de um serviço, já normalizados para gravar:
/// textos opcionais vazios viram `null`. Valores em centavos.
class Servico {
  Servico({
    required String nome,
    required this.categoriaId,
    required this.precoCobradoCentavos,
    this.custoMateriaisCentavos,
    this.duracaoMinutos,
    String? observacoes,
    this.caminhoFoto,
  }) : nome = nome.trim(),
       observacoes = _textoOuNulo(observacoes);

  final String nome;
  final String categoriaId;
  final int precoCobradoCentavos;
  final int? custoMateriaisCentavos;
  final int? duracaoMinutos;
  final String? observacoes;

  /// Caminho no bucket `fotos` (`<id>/servicos/<momento>.jpg`) ou `null`.
  final String? caminhoFoto;

  /// Colunas de `servicos` (sem `id`, `consultora_id` nem `created_at`).
  Map<String, dynamic> paraGravar() => {
    'nome': nome,
    'categoria_id': categoriaId,
    'preco_cobrado': precoCobradoCentavos / 100,
    'custo_materiais': custoMateriaisCentavos == null
        ? null
        : custoMateriaisCentavos! / 100,
    'duracao_minutos': duracaoMinutos,
    'observacoes': observacoes,
    'foto_url': caminhoFoto,
  };

  Servico comFoto(String? caminho) => Servico(
    nome: nome,
    categoriaId: categoriaId,
    precoCobradoCentavos: precoCobradoCentavos,
    custoMateriaisCentavos: custoMateriaisCentavos,
    duracaoMinutos: duracaoMinutos,
    observacoes: observacoes,
    caminhoFoto: caminho,
  );

  static String? validarNome(String texto) =>
      texto.trim().isEmpty ? 'Informe o nome do serviço' : null;

  static String? validarCategoria(String? categoriaId) =>
      categoriaId == null ? 'Escolha a categoria' : null;

  static String? validarPreco(int? centavos) =>
      centavos == null || centavos <= 0 ? 'Informe o preço cobrado' : null;

  static String? _textoOuNulo(String? texto) {
    final limpo = texto?.trim() ?? '';
    return limpo.isEmpty ? null : limpo;
  }
}
