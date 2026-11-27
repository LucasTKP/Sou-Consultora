import 'dart:typed_data';

import 'package:sou_consultora/core/dto/catalogo_produto_dto.dart';
import 'package:sou_consultora/core/erros/falha_app.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/texto_busca.dart';
import 'package:sou_consultora/core/repository/repositorio_catalogo.dart';
import 'package:sou_consultora/core/service/servico_catalogo.dart';

CatalogoProdutoDto catalogoDto(
  String codigo,
  String nome, {
  String marca = 'Natura',
  String? categoria = 'Maquiagem',
  String? foto,
}) => CatalogoProdutoDto(
  id: 'id-$codigo',
  marca: marca,
  codigo: codigo,
  nome: nome,
  categoria: categoria,
  fotoCaminho: foto ?? '${marca.toLowerCase()}/$codigo.jpg',
);

/// Catálogo em memória: filtra por marca e nome como o banco faria.
class ServicoCatalogoFalso implements ServicoCatalogo {
  ServicoCatalogoFalso({List<CatalogoProdutoDto>? itens}) : itens = itens ?? [];

  List<CatalogoProdutoDto> itens;
  bool falharListar = false;
  bool falharUrls = false;
  bool falharFoto = false;
  /// PNG 1x1 válido (a tela decodifica a foto de verdade).
  Uint8List bytesDaFoto = Uint8List.fromList(<int>[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 218, 99, 252, 207, 192, 80, 15, 0, 4, 133, 1, 128, 132, 169, 140, 33, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130]);
  final List<({String? marca, String texto})> buscas = [];
  final List<String> fotosBaixadas = [];

  @override
  Future<Resultado<List<CatalogoProdutoDto>>> listar({
    String? marca,
    String texto = '',
    int limite = 60,
  }) async {
    buscas.add((marca: marca, texto: texto));
    if (falharListar) return Erro(const FalhaRede('Sem conexão.'));
    return Sucesso(
      [
        for (final item in itens)
          if ((marca == null || item.marca == marca) &&
              TextoBusca.contem(item.nome, texto))
            item,
      ].take(limite).toList(),
    );
  }

  @override
  Future<Resultado<Map<String, String>>> urlsFotos(
    List<String> caminhos,
  ) async {
    if (falharUrls) return Erro(const FalhaRede('Sem conexão.'));
    return Sucesso({for (final c in caminhos) c: 'https://assinada/$c'});
  }

  @override
  Future<Resultado<Uint8List>> baixarFoto(String caminho) async {
    fotosBaixadas.add(caminho);
    if (falharFoto) return Erro(const FalhaRede('Sem conexão.'));
    return Sucesso(bytesDaFoto);
  }
}

RepositorioCatalogo repositorioCatalogoDeTeste([
  ServicoCatalogoFalso? servico,
]) => RepositorioCatalogo(servico: servico ?? ServicoCatalogoFalso());
