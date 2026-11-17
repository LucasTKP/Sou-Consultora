import 'dart:typed_data';

import 'package:sou_consultora/core/model/categoria.dart';
import 'package:sou_consultora/core/model/margem.dart';

class ServicosFormularioState {
  const ServicosFormularioState({
    this.idServico,
    this.carregando = true,
    this.erroCarregar,
    this.categorias = const [],
    this.nome = '',
    this.categoriaId,
    this.preco,
    this.custo,
    this.duracaoMinutos,
    this.observacoes = '',
    this.caminhoFotoAtual,
    this.urlFotoAtual,
    this.fotoNova,
    this.fotoRemovida = false,
    this.erroNome,
    this.erroCategoria,
    this.erroPreco,
    this.salvando = false,
    this.salvo = false,
    this.aviso,
    this.versaoPreenchimento = 0,
  });

  /// Nulo = novo serviço.
  final String? idServico;
  final bool carregando;
  final String? erroCarregar;
  final List<Categoria> categorias;
  final String nome;
  final String? categoriaId;

  /// Centavos.
  final int? preco;
  final int? custo;
  final int? duracaoMinutos;
  final String observacoes;
  final String? caminhoFotoAtual;
  final String? urlFotoAtual;
  final Uint8List? fotoNova;
  final bool fotoRemovida;
  final String? erroNome;
  final String? erroCategoria;
  final String? erroPreco;
  final bool salvando;
  final bool salvo;
  final String? aviso;
  final int versaoPreenchimento;

  bool get editando => idServico != null;

  Categoria? get categoriaEscolhida =>
      categorias.where((c) => c.id == categoriaId).firstOrNull;

  /// Retorno estimado (só com preço informado).
  Margem? get retorno {
    final valor = preco;
    if (valor == null || valor <= 0) return null;
    return Margem.calcular(precoVenda: valor, custo: custo ?? 0);
  }

  String? get urlFotoVisivel =>
      fotoNova != null || fotoRemovida ? null : urlFotoAtual;

  bool get temFoto =>
      fotoNova != null || (!fotoRemovida && caminhoFotoAtual != null);

  ServicosFormularioState copyWith({
    bool? carregando,
    String? Function()? erroCarregar,
    List<Categoria>? categorias,
    String? nome,
    String? Function()? categoriaId,
    int? Function()? preco,
    int? Function()? custo,
    int? Function()? duracaoMinutos,
    String? observacoes,
    String? Function()? caminhoFotoAtual,
    String? Function()? urlFotoAtual,
    Uint8List? Function()? fotoNova,
    bool? fotoRemovida,
    String? Function()? erroNome,
    String? Function()? erroCategoria,
    String? Function()? erroPreco,
    bool? salvando,
    bool? salvo,
    String? Function()? aviso,
    int? versaoPreenchimento,
  }) {
    return ServicosFormularioState(
      idServico: idServico,
      carregando: carregando ?? this.carregando,
      erroCarregar: erroCarregar != null ? erroCarregar() : this.erroCarregar,
      categorias: categorias ?? this.categorias,
      nome: nome ?? this.nome,
      categoriaId: categoriaId != null ? categoriaId() : this.categoriaId,
      preco: preco != null ? preco() : this.preco,
      custo: custo != null ? custo() : this.custo,
      duracaoMinutos: duracaoMinutos != null
          ? duracaoMinutos()
          : this.duracaoMinutos,
      observacoes: observacoes ?? this.observacoes,
      caminhoFotoAtual: caminhoFotoAtual != null
          ? caminhoFotoAtual()
          : this.caminhoFotoAtual,
      urlFotoAtual: urlFotoAtual != null ? urlFotoAtual() : this.urlFotoAtual,
      fotoNova: fotoNova != null ? fotoNova() : this.fotoNova,
      fotoRemovida: fotoRemovida ?? this.fotoRemovida,
      erroNome: erroNome != null ? erroNome() : this.erroNome,
      erroCategoria: erroCategoria != null
          ? erroCategoria()
          : this.erroCategoria,
      erroPreco: erroPreco != null ? erroPreco() : this.erroPreco,
      salvando: salvando ?? this.salvando,
      salvo: salvo ?? this.salvo,
      aviso: aviso != null ? aviso() : this.aviso,
      versaoPreenchimento: versaoPreenchimento ?? this.versaoPreenchimento,
    );
  }
}
