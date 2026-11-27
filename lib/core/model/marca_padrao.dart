import 'package:sou_consultora/core/model/fornecedor.dart';

/// Marcas que a consultora pode marcar no cadastro; cada uma vira um fornecedor.
enum MarcaPadrao {
  natura('Natura', 'Cosméticos e perfumaria'),
  avon('Avon', 'Cosméticos e perfumaria'),
  boticario('O Boticário', 'Cosméticos e perfumaria'),
  eudora('Eudora', 'Cosméticos e perfumaria'),
  tupperware('Tupperware', 'Utilidades domésticas'),
  maryKay('Mary Kay', 'Cosméticos');

  const MarcaPadrao(this.nome, this.ramo);

  final String nome;
  final String ramo;

  Fornecedor paraFornecedor() => Fornecedor(nome: nome, ramo: ramo);
}
