/// Ordem alfabética das listas (clientes, fornecedores...).
enum OrdemNome {
  aZ('Nome: A-Z'),
  zA('Nome: Z-A');

  const OrdemNome(this.rotulo);

  final String rotulo;

  OrdemNome get inversa => this == aZ ? zA : aZ;
}
