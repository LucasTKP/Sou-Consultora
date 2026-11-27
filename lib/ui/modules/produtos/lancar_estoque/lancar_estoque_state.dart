import 'package:sou_consultora/core/model/item_lancamento.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

class LancarEstoqueState {
  const LancarEstoqueState({
    required this.dataCompra,
    this.itens = const [],
    this.produtos = const [],
    this.carregandoProdutos = true,
    this.erroProdutos,
    this.erroData,
    this.salvando = false,
    this.salvo = false,
    this.aviso,
    this.produtoInicialId,
  });

  final DateTime dataCompra;
  final List<ItemLancamento> itens;

  /// Produtos que podem entrar na compra (todos os da consultora).
  final List<ResumoProduto> produtos;
  final bool carregandoProdutos;
  final String? erroProdutos;
  final String? erroData;
  final bool salvando;
  final bool salvo;

  /// Mensagem passageira (falha ao salvar).
  final AvisoToast? aviso;

  /// Produto vindo da rota: a folha de item abre com ele escolhido.
  final String? produtoInicialId;

  LancamentoEstoque get lancamento =>
      LancamentoEstoque(dataCompra: dataCompra, itens: itens);

  bool get podeSalvar => itens.isNotEmpty && erroData == null && !salvando;

  ResumoProduto? get produtoInicial =>
      produtos.where((p) => p.id == produtoInicialId).firstOrNull;

  LancarEstoqueState copyWith({
    DateTime? dataCompra,
    List<ItemLancamento>? itens,
    List<ResumoProduto>? produtos,
    bool? carregandoProdutos,
    String? Function()? erroProdutos,
    String? Function()? erroData,
    bool? salvando,
    bool? salvo,
    AvisoToast? Function()? aviso,
    String? Function()? produtoInicialId,
  }) {
    return LancarEstoqueState(
      dataCompra: dataCompra ?? this.dataCompra,
      itens: itens ?? this.itens,
      produtos: produtos ?? this.produtos,
      carregandoProdutos: carregandoProdutos ?? this.carregandoProdutos,
      erroProdutos: erroProdutos != null ? erroProdutos() : this.erroProdutos,
      erroData: erroData != null ? erroData() : this.erroData,
      salvando: salvando ?? this.salvando,
      salvo: salvo ?? this.salvo,
      aviso: aviso != null ? aviso() : this.aviso,
      produtoInicialId: produtoInicialId != null
          ? produtoInicialId()
          : this.produtoInicialId,
    );
  }
}
