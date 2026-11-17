import 'package:sou_consultora/core/erros/resultado.dart';
import 'package:sou_consultora/core/model/item_lancamento.dart';
import 'package:sou_consultora/core/model/lote_produto.dart';
import 'package:sou_consultora/core/model/saida_produto.dart';
import 'package:sou_consultora/core/repository/repositorio_produtos.dart';
import 'package:sou_consultora/core/service/servico_estoque.dart';

/// Estoque por produto. Depois de lançar ou apagar um lote, recarrega os
/// produtos (saldo e situação da lista e dos detalhes).
class RepositorioEstoque {
  RepositorioEstoque({required this._servico, required this._produtos});

  final ServicoEstoque _servico;
  final RepositorioProdutos _produtos;

  Future<Resultado<List<LoteProduto>>> lotes(String produtoId) async {
    final resultado = await _servico.listarLotes(produtoId);
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso([
        for (final dto in valor) dto.paraModel(),
      ]),
    };
  }

  Future<Resultado<List<SaidaProduto>>> saidas(String produtoId) async {
    final resultado = await _servico.listarSaidas(produtoId);
    return switch (resultado) {
      Erro(:final falha) => Erro(falha),
      Sucesso(:final valor) => Sucesso([
        for (final dto in valor) dto.paraModel(),
      ]),
    };
  }

  Future<Resultado<int>> lancar(LancamentoEstoque lancamento) async {
    final resultado = await _servico.lancar(lancamento);
    // A gravação já valeu; se recarregar falhar, a lista atualiza na próxima abertura.
    if (resultado is Sucesso<int>) await _produtos.carregar();
    return resultado;
  }

  Future<Resultado<void>> apagarLote(String loteId) async {
    final resultado = await _servico.apagarLote(loteId);
    if (resultado is Sucesso<void>) await _produtos.carregar();
    return resultado;
  }
}
