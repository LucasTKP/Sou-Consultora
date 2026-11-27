/// Categoria de produto (as padrão são copiadas no cadastro da consultora).
class Categoria {
  const Categoria({required this.id, required this.nome});

  final String id;
  final String nome;

  @override
  bool operator ==(Object other) =>
      other is Categoria && other.id == id && other.nome == nome;

  @override
  int get hashCode => Object.hash(id, nome);
}
