import 'package:sou_consultora/core/model/margem.dart';
import 'package:sou_consultora/core/model/servico.dart';
import 'package:sou_consultora/core/model/texto_busca.dart';

/// Serviço com o nome da categoria (view `resumo_servicos`). Valores em centavos.
class ResumoServico {
  const ResumoServico({
    required this.id,
    required this.nome,
    required this.categoriaId,
    required this.categoriaNome,
    required this.precoCobrado,
    required this.criadoEm,
    this.custoMateriais,
    this.duracaoMinutos,
    this.observacoes,
    this.caminhoFoto,
    this.urlFoto,
  });

  final String id;
  final String nome;
  final String categoriaId;
  final String categoriaNome;
  final int precoCobrado;
  final int? custoMateriais;
  final int? duracaoMinutos;
  final String? observacoes;
  final String? caminhoFoto;

  /// URL assinada para exibir a foto (temporária).
  final String? urlFoto;
  final DateTime criadoEm;

  /// Lucro: preço cobrado − custo de materiais.
  Margem get retorno =>
      Margem.calcular(precoVenda: precoCobrado, custo: custoMateriais ?? 0);

  bool combinaBusca(String busca) => TextoBusca.contem(nome, busca);

  Servico paraServico() => Servico(
    nome: nome,
    categoriaId: categoriaId,
    precoCobradoCentavos: precoCobrado,
    custoMateriaisCentavos: custoMateriais,
    duracaoMinutos: duracaoMinutos,
    observacoes: observacoes,
    caminhoFoto: caminhoFoto,
  );
}
