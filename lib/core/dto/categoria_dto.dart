import 'package:sou_consultora/core/model/categoria.dart';

/// Espelho da tabela `categorias` (só as colunas que o app lê).
class CategoriaDto {
  const CategoriaDto({
    required this.id,
    required this.nome,
    required this.tipo,
  });

  factory CategoriaDto.fromJson(Map<String, dynamic> json) {
    return CategoriaDto(
      id: json['id'] as String,
      nome: json['nome'] as String,
      tipo: json['tipo'] as String,
    );
  }

  final String id;
  final String nome;

  /// `produto` ou `servico`.
  final String tipo;

  Categoria paraModel() => Categoria(id: id, nome: nome);
}
