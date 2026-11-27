import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sou_consultora/core/di/injetor.dart';
import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/produto_catalogo.dart';
import 'package:sou_consultora/core/repository/repositorio_catalogo.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/ui/modules/produtos/importar/produtos_importar_state.dart';

/// Lista do catálogo das marcas, com filtro por marca e busca por nome.
class ProdutosImportarCubit extends Cubit<ProdutosImportarState> {
  ProdutosImportarCubit({
    RepositorioCatalogo? catalogo,
    RepositorioProdutos? produtos,
    this.esperaBusca = const Duration(milliseconds: 350),
  }) : _catalogo = catalogo ?? injetor<RepositorioCatalogo>(),
       _produtos = produtos ?? injetor<RepositorioProdutos>(),
       super(const ProdutosImportarState()) {
    carregarJaCadastrados();
    carregar();
  }

  final RepositorioCatalogo _catalogo;
  final RepositorioProdutos _produtos;
  final Duration esperaBusca;
  Timer? _espera;

  /// Cada busca ganha um número; respostas de buscas antigas são ignoradas.
  int _busca = 0;

  /// Marca na lista o que a consultora já tem. Se falhar, a lista segue sem os
  /// selos e o banco continua barrando o código repetido ao salvar.
  Future<void> carregarJaCadastrados() async {
    final resultado = await _produtos.carregar();
    if (isClosed) return;
    if (resultado case Sucesso(:final valor)) {
      emit(
        state.copyWith(
          jaCadastrados: {
            for (final produto in valor)
              if (produto.codigo != null)
                ProdutoCatalogo.chaveDeProduto(
                  produto.fornecedorNome,
                  produto.codigo!,
                ),
          },
        ),
      );
    }
  }

  Future<void> carregar() async {
    final numero = ++_busca;
    emit(state.copyWith(carregando: true, erro: () => null));
    final resultado = await _catalogo.buscar(
      marca: state.marca,
      texto: state.texto,
    );
    if (isClosed || numero != _busca) return;
    switch (resultado) {
      case Erro(:final falha):
        emit(state.copyWith(carregando: false, erro: () => falha.mensagem));
      case Sucesso(:final valor):
        emit(state.copyWith(carregando: false, itens: valor));
    }
  }

  void alterarMarca(String? marca) {
    if (marca == state.marca) return;
    emit(state.copyWith(marca: () => marca));
    carregar();
  }

  /// Espera a pessoa parar de digitar antes de consultar.
  void alterarBusca(String texto) {
    emit(state.copyWith(texto: texto));
    _espera?.cancel();
    _espera = Timer(esperaBusca, carregar);
  }

  @override
  Future<void> close() {
    _espera?.cancel();
    return super.close();
  }
}
