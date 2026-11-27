import 'dart:typed_data';

import 'package:sou_consultora/core/dto/catalogo_produto_dto.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/produto_catalogo.dart';
import 'package:sou_consultora/core/service/servico_catalogo.dart';

/// Catálogo das marcas, para importar no cadastro de produto.
class RepositorioCatalogo {
  RepositorioCatalogo({required this._servico});

  final ServicoCatalogo _servico;

  /// Busca por [marca] e por [texto] (nome). Falha ao gerar as URLs das fotos
  /// não derruba a lista: os itens aparecem sem miniatura.
  Future<Resultado<List<ProdutoCatalogo>>> buscar({
    String? marca,
    String texto = '',
  }) async {
    final limpo = texto
        .replaceAll(RegExp(r'[%_*,()\\]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final resultado = await _servico.listar(marca: marca, texto: limpo);
    final List<CatalogoProdutoDto> dtos;
    switch (resultado) {
      case Erro(:final falha):
        return Erro(falha);
      case Sucesso(:final valor):
        dtos = valor;
    }

    final caminhos = [
      for (final dto in dtos)
        if (dto.fotoCaminho != null) dto.fotoCaminho!,
    ];
    final urls = switch (await _servico.urlsFotos(caminhos)) {
      Sucesso(:final valor) => valor,
      Erro() => const <String, String>{},
    };
    return Sucesso([
      for (final dto in dtos) dto.paraModel(urlFoto: urls[dto.fotoCaminho]),
    ]);
  }

  /// Bytes da foto do [produto] (null se ele não tem foto).
  Future<Resultado<Uint8List?>> baixarFoto(ProdutoCatalogo produto) async {
    final caminho = produto.caminhoFoto;
    if (caminho == null) return const Sucesso(null);
    return switch (await _servico.baixarFoto(caminho)) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso(valor),
    };
  }
}
