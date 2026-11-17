import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/categoria.dart';
import 'package:sou_consultora/core/model/origem_foto.dart';
import 'package:sou_consultora/core/model/mudanca_foto.dart';
import 'package:sou_consultora/core/model/produto.dart';
import 'package:sou_consultora/core/model/resumo_fornecedor.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/core/repository/repositorio_categorias.dart';
import 'package:sou_consultora/core/repository/repositorio_fornecedores.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/ui/modules/produtos/formulario/produtos_formulario_state.dart';

/// Cadastro de produto em 2 passos: novo ([idProduto] nulo) ou edição.
class ProdutosFormularioCubit extends Cubit<ProdutosFormularioState> {
  ProdutosFormularioCubit({
    String? idProduto,
    RepositorioProdutos? produtos,
    RepositorioFornecedores? fornecedores,
    RepositorioCategorias? categorias,
  }) : _produtos = produtos ?? injetor<RepositorioProdutos>(),
       _fornecedores = fornecedores ?? injetor<RepositorioFornecedores>(),
       _categorias = categorias ?? injetor<RepositorioCategorias>(),
       super(ProdutosFormularioState(idProduto: idProduto)) {
    carregar();
  }

  final RepositorioProdutos _produtos;
  final RepositorioFornecedores _fornecedores;
  final RepositorioCategorias _categorias;

  /// Marcas e categorias para os seletores e, na edição, os dados do produto.
  Future<void> carregar() async {
    emit(state.copyWith(carregando: true, erroCarregar: () => null));
    final (marcas, categorias) = await (
      _fornecedores.carregar(),
      _categorias.deProduto(),
    ).wait;
    if (isClosed) return;
    switch ((marcas, categorias)) {
      case (Erro(:final falha), _) || (_, Erro(:final falha)):
        emit(
          state.copyWith(carregando: false, erroCarregar: () => falha.mensagem),
        );
        return;
      case (Sucesso(valor: final marcas), Sucesso(valor: final categorias)):
        emit(state.copyWith(marcas: marcas, categorias: categorias));
    }
    if (!state.editando) {
      emit(state.copyWith(carregando: false));
      return;
    }
    await _carregarProduto();
  }

  /// Na volta do atalho "Novo fornecedor": a marca nova aparece no seletor.
  Future<void> recarregarMarcas() async {
    final resultado = await _fornecedores.carregar();
    if (isClosed) return;
    if (resultado case Sucesso(:final valor)) {
      emit(state.copyWith(marcas: valor));
    }
  }

  // —— Passo 1 ——

  void alterarNome(String texto) =>
      emit(state.copyWith(nome: texto, erroNome: () => null));

  void alterarMarca(ResumoFornecedor marca) =>
      emit(state.copyWith(fornecedorId: () => marca.id, erroMarca: () => null));

  void alterarCategoria(Categoria categoria) => emit(
    state.copyWith(categoriaId: () => categoria.id, erroCategoria: () => null),
  );

  void alterarCodigo(String texto) => emit(state.copyWith(codigo: texto));

  Future<void> escolherFoto(OrigemFoto origem) async {
    final resultado = await _produtos.escolherFoto(origem);
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(state.copyWith(aviso: () => falha.mensagem));
      case Sucesso(valor: null):
        return;
      case Sucesso(:final valor?):
        emit(state.copyWith(fotoNova: () => valor, fotoRemovida: false));
    }
  }

  void removerFoto() => emit(
    state.copyWith(
      fotoNova: () => null,
      fotoRemovida: state.caminhoFotoAtual != null,
    ),
  );

  /// Vai ao passo 2 se o passo 1 estiver completo.
  void continuar() {
    if (_validarPasso1()) emit(state.copyWith(passo: 2));
  }

  // —— Passo 2 ——

  void voltar() => emit(state.copyWith(passo: 1));

  void alterarPrecoVenda(int centavos) => emit(
    state.copyWith(precoVenda: () => centavos, erroPrecoVenda: () => null),
  );

  /// Custo zero conta como "não informado".
  void alterarPrecoCusto(int centavos) =>
      emit(state.copyWith(precoCusto: () => centavos == 0 ? null : centavos));

  void alterarDurabilidade(int? dias) =>
      emit(state.copyWith(durabilidadeDias: () => dias));

  void alterarObservacoes(String texto) =>
      emit(state.copyWith(observacoes: texto));

  void limparAviso() => emit(state.copyWith(aviso: () => null));

  Future<void> salvar() async {
    if (state.salvando || !_validarPasso2()) return;

    emit(state.copyWith(salvando: true));
    final resultado = await _produtos.salvar(
      _produto(),
      id: state.idProduto,
      foto: _mudancaFoto(),
    );
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(state.copyWith(salvando: false, aviso: () => falha.mensagem));
      case Sucesso():
        emit(state.copyWith(salvando: false, salvo: true));
    }
  }

  Future<void> _carregarProduto() async {
    final resultado = await _produtos.buscarResumo(state.idProduto!);
    if (isClosed) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(
          state.copyWith(carregando: false, erroCarregar: () => falha.mensagem),
        );
      case Sucesso(valor: null):
        emit(
          state.copyWith(
            carregando: false,
            erroCarregar: () => 'Produto não encontrado.',
          ),
        );
      case Sucesso(valor: final ResumoProduto produto):
        _preencher(produto);
    }
  }

  void _preencher(ResumoProduto produto) {
    emit(
      state.copyWith(
        carregando: false,
        nome: produto.nome,
        fornecedorId: () => produto.fornecedorId,
        fornecedorIdOriginal: () => produto.fornecedorId,
        categoriaId: () => produto.categoriaId,
        codigo: produto.codigo ?? '',
        precoVenda: () => produto.precoVenda,
        precoCusto: () => produto.precoCusto,
        durabilidadeDias: () => produto.durabilidadeDias,
        observacoes: produto.observacoes ?? '',
        caminhoFotoAtual: () => produto.caminhoFoto,
        urlFotoAtual: () => produto.urlFoto,
        versaoPreenchimento: state.versaoPreenchimento + 1,
      ),
    );
  }

  bool _validarPasso1() {
    final erroNome = Produto.validarNome(state.nome);
    final erroMarca = Produto.validarMarca(state.fornecedorId);
    final erroCategoria = Produto.validarCategoria(state.categoriaId);
    emit(
      state.copyWith(
        erroNome: () => erroNome,
        erroMarca: () => erroMarca,
        erroCategoria: () => erroCategoria,
      ),
    );
    return erroNome == null && erroMarca == null && erroCategoria == null;
  }

  bool _validarPasso2() {
    final erroPreco = Produto.validarPrecoVenda(state.precoVenda);
    emit(state.copyWith(erroPrecoVenda: () => erroPreco));
    return erroPreco == null;
  }

  Produto _produto() => Produto(
    nome: state.nome,
    fornecedorId: state.fornecedorId!,
    categoriaId: state.categoriaId!,
    precoVendaCentavos: state.precoVenda!,
    codigo: state.codigo,
    precoCustoCentavos: state.precoCusto,
    durabilidadeDias: state.durabilidadeDias,
    observacoes: state.observacoes,
    caminhoFoto: state.caminhoFotoAtual,
  );

  MudancaFoto _mudancaFoto() {
    if (state.fotoNova case final bytes?) return TrocarFoto(bytes);
    if (state.fotoRemovida) return const RemoverFoto();
    return const ManterFoto();
  }
}
