import 'dart:typed_data';

import 'package:sou_consultora/core/model/categoria.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

class ProdutosFormularioState {
  const ProdutosFormularioState({
    this.idProduto,
    this.carregando = true,
    this.erroCarregar,
    this.passo = 1,
    this.marcas = const [],
    this.categorias = const [],
    this.nome = '',
    this.fornecedorId,
    this.fornecedorIdOriginal,
    this.categoriaId,
    this.codigo = '',
    this.precoVenda,
    this.precoCusto,
    this.durabilidadeDias,
    this.observacoes = '',
    this.caminhoFotoAtual,
    this.urlFotoAtual,
    this.fotoNova,
    this.fotoRemovida = false,
    this.erroNome,
    this.erroMarca,
    this.erroCategoria,
    this.erroPrecoVenda,
    this.salvando = false,
    this.salvo = false,
    this.aviso,
    this.versaoPreenchimento = 0,
  });

  static const totalPassos = 2;

  /// Nulo = novo produto.
  final String? idProduto;
  final bool carregando;
  final String? erroCarregar;

  /// 1 = dados do produto; 2 = preços e durabilidade.
  final int passo;

  /// Todas as marcas da consultora (o seletor mostra só [marcasDisponiveis]).
  final List<ResumoFornecedor> marcas;
  final List<Categoria> categorias;
  final String nome;
  final String? fornecedorId;

  /// Marca do produto ao abrir a edição (aparece mesmo se estiver em espera).
  final String? fornecedorIdOriginal;
  final String? categoriaId;
  final String codigo;

  /// Valores em centavos.
  final int? precoVenda;
  final int? precoCusto;
  final int? durabilidadeDias;
  final String observacoes;

  /// Foto já gravada no produto (caminho no bucket e URL para exibir).
  final String? caminhoFotoAtual;
  final String? urlFotoAtual;

  /// Foto escolhida agora, ainda não enviada.
  final Uint8List? fotoNova;

  /// A consultora tirou a foto que o produto tinha.
  final bool fotoRemovida;
  final String? erroNome;
  final String? erroMarca;
  final String? erroCategoria;
  final String? erroPrecoVenda;
  final bool salvando;
  final bool salvo;

  /// Mensagem passageira (falha ao salvar, ao escolher foto...).
  final AvisoToast? aviso;

  /// Muda quando o cubit preenche os campos (edição carregada).
  final int versaoPreenchimento;

  bool get editando => idProduto != null;

  /// Marcas ativas, mais a marca atual do produto se estiver em espera.
  List<ResumoFornecedor> get marcasDisponiveis => [
    for (final marca in marcas)
      if (marca.ativo || marca.id == fornecedorIdOriginal) marca,
  ];

  ResumoFornecedor? get marcaEscolhida =>
      marcas.where((m) => m.id == fornecedorId).firstOrNull;

  Categoria? get categoriaEscolhida =>
      categorias.where((c) => c.id == categoriaId).firstOrNull;

  /// URL da foto gravada que ainda vale (nula se foi trocada ou removida).
  String? get urlFotoVisivel =>
      fotoNova != null || fotoRemovida ? null : urlFotoAtual;

  bool get temFoto =>
      fotoNova != null || (!fotoRemovida && caminhoFotoAtual != null);

  ProdutosFormularioState copyWith({
    bool? carregando,
    String? Function()? erroCarregar,
    int? passo,
    List<ResumoFornecedor>? marcas,
    List<Categoria>? categorias,
    String? nome,
    String? Function()? fornecedorId,
    String? Function()? fornecedorIdOriginal,
    String? Function()? categoriaId,
    String? codigo,
    int? Function()? precoVenda,
    int? Function()? precoCusto,
    int? Function()? durabilidadeDias,
    String? observacoes,
    String? Function()? caminhoFotoAtual,
    String? Function()? urlFotoAtual,
    Uint8List? Function()? fotoNova,
    bool? fotoRemovida,
    String? Function()? erroNome,
    String? Function()? erroMarca,
    String? Function()? erroCategoria,
    String? Function()? erroPrecoVenda,
    bool? salvando,
    bool? salvo,
    AvisoToast? Function()? aviso,
    int? versaoPreenchimento,
  }) {
    return ProdutosFormularioState(
      idProduto: idProduto,
      carregando: carregando ?? this.carregando,
      erroCarregar: erroCarregar != null ? erroCarregar() : this.erroCarregar,
      passo: passo ?? this.passo,
      marcas: marcas ?? this.marcas,
      categorias: categorias ?? this.categorias,
      nome: nome ?? this.nome,
      fornecedorId: fornecedorId != null ? fornecedorId() : this.fornecedorId,
      fornecedorIdOriginal: fornecedorIdOriginal != null
          ? fornecedorIdOriginal()
          : this.fornecedorIdOriginal,
      categoriaId: categoriaId != null ? categoriaId() : this.categoriaId,
      codigo: codigo ?? this.codigo,
      precoVenda: precoVenda != null ? precoVenda() : this.precoVenda,
      precoCusto: precoCusto != null ? precoCusto() : this.precoCusto,
      durabilidadeDias: durabilidadeDias != null
          ? durabilidadeDias()
          : this.durabilidadeDias,
      observacoes: observacoes ?? this.observacoes,
      caminhoFotoAtual: caminhoFotoAtual != null
          ? caminhoFotoAtual()
          : this.caminhoFotoAtual,
      urlFotoAtual: urlFotoAtual != null ? urlFotoAtual() : this.urlFotoAtual,
      fotoNova: fotoNova != null ? fotoNova() : this.fotoNova,
      fotoRemovida: fotoRemovida ?? this.fotoRemovida,
      erroNome: erroNome != null ? erroNome() : this.erroNome,
      erroMarca: erroMarca != null ? erroMarca() : this.erroMarca,
      erroCategoria: erroCategoria != null
          ? erroCategoria()
          : this.erroCategoria,
      erroPrecoVenda: erroPrecoVenda != null
          ? erroPrecoVenda()
          : this.erroPrecoVenda,
      salvando: salvando ?? this.salvando,
      salvo: salvo ?? this.salvo,
      aviso: aviso != null ? aviso() : this.aviso,
      versaoPreenchimento: versaoPreenchimento ?? this.versaoPreenchimento,
    );
  }
}
