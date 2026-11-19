/// Passo a passo de apresentação que aparece só na primeira vez (cada dica uma vez).
enum DicaApp {
  /// Cadastro de produto novo: apresenta o botão "Importar do catálogo".
  importarNoFormulario('importar_no_formulario'),

  /// Tela de importar: busca, filtro por marca e escolha do produto.
  importarNaLista('importar_na_lista'),

  /// De volta ao cadastro com o produto importado: leva ao "Continuar".
  continuarAposImportar('continuar_apos_importar');

  const DicaApp(this.chave);

  /// Nome estável usado para guardar que a dica já foi vista.
  final String chave;
}
