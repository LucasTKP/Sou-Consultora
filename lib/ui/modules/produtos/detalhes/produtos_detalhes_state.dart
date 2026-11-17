import 'package:sou_consultora/core/model/lote_produto.dart';
import 'package:sou_consultora/core/model/resumo_estoque.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/core/model/saida_produto.dart';

enum AbaProduto { informacoes, estoque }

enum SegmentoEstoque { entradas, saidas }

class ProdutosDetalhesState {
  const ProdutosDetalhesState({
    this.produto,
    this.carregando = true,
    this.erro,
    this.aviso,
    this.aba = AbaProduto.informacoes,
    this.segmento = SegmentoEstoque.entradas,
    this.lotes = const [],
    this.saidas = const [],
    this.carregandoEstoque = true,
    this.erroEstoque,
  });

  final ResumoProduto? produto;
  final bool carregando;
  final String? erro;

  /// Mensagem passageira (falha ao atualizar com o produto já na tela,
  /// lote apagado, lote com vendas...).
  final String? aviso;
  final AbaProduto aba;
  final SegmentoEstoque segmento;
  final List<LoteProduto> lotes;
  final List<SaidaProduto> saidas;
  final bool carregandoEstoque;
  final String? erroEstoque;

  ResumoEstoque get resumoEstoque => ResumoEstoque.dosLotes(lotes);

  ProdutosDetalhesState copyWith({
    ResumoProduto? produto,
    bool? carregando,
    String? Function()? erro,
    String? Function()? aviso,
    AbaProduto? aba,
    SegmentoEstoque? segmento,
    List<LoteProduto>? lotes,
    List<SaidaProduto>? saidas,
    bool? carregandoEstoque,
    String? Function()? erroEstoque,
  }) {
    return ProdutosDetalhesState(
      produto: produto ?? this.produto,
      carregando: carregando ?? this.carregando,
      erro: erro != null ? erro() : this.erro,
      aviso: aviso != null ? aviso() : this.aviso,
      aba: aba ?? this.aba,
      segmento: segmento ?? this.segmento,
      lotes: lotes ?? this.lotes,
      saidas: saidas ?? this.saidas,
      carregandoEstoque: carregandoEstoque ?? this.carregandoEstoque,
      erroEstoque: erroEstoque != null ? erroEstoque() : this.erroEstoque,
    );
  }
}
