import 'package:sou_consultora/core/model/forma_pagamento.dart';
import 'package:sou_consultora/core/model/item_venda.dart';
import 'package:sou_consultora/core/model/pedido_venda.dart';
import 'package:sou_consultora/core/model/plano_parcelas.dart';
import 'package:sou_consultora/core/model/resumo_cliente.dart';
import 'package:sou_consultora/core/model/resumo_produto.dart';
import 'package:sou_consultora/core/model/resumo_servico.dart';
import 'package:sou_consultora/ui/widgets/feedback/aviso_toast.dart';

class NovaVendaState {
  const NovaVendaState({
    required this.dataVenda,
    this.idVenda,
    this.carregando = true,
    this.erroCarregar,
    this.passo = 1,
    this.clientes = const [],
    this.produtos = const [],
    this.servicos = const [],
    this.clienteId,
    this.itens = const [],
    this.aVista = true,
    this.parcelas = const [],
    this.versaoPlano = 0,
    this.entradaRecebida = false,
    this.formaEntrada = FormaPagamento.pix,
    this.observacoes = '',
    this.erroCliente,
    this.erroItens,
    this.erroData,
    this.salvando = false,
    this.idSalvo,
    this.aviso,
    this.versaoPreenchimento = 0,
  });

  static const totalPassos = 2;

  /// Nulo = nova venda.
  final String? idVenda;
  final bool carregando;
  final String? erroCarregar;
  final int passo;
  final List<ResumoCliente> clientes;
  final List<ResumoProduto> produtos;
  final List<ResumoServico> servicos;
  final String? clienteId;
  final List<ItemPedido> itens;
  final DateTime dataVenda;
  final bool aVista;
  final List<ParcelaPlano> parcelas;

  /// Muda quando o app sugere um plano novo (os campos de valor se refazem).
  final int versaoPlano;
  final bool entradaRecebida;
  final FormaPagamento formaEntrada;
  final String observacoes;
  final String? erroCliente;
  final String? erroItens;
  final String? erroData;
  final bool salvando;

  /// Id da venda gravada (a tela fecha com ele).
  final String? idSalvo;
  final AvisoToast? aviso;
  final int versaoPreenchimento;

  bool get editando => idVenda != null;

  ResumoCliente? get cliente =>
      clientes.where((c) => c.id == clienteId).firstOrNull;

  int get subtotal => PedidoVenda.subtotalDe(itens);

  int get descontos => PedidoVenda.descontosDe(itens);

  int get total => PedidoVenda.totalDe(itens);

  /// Positivo = falta; negativo = sobra.
  int get diferenca => PlanoParcelas.diferenca(total, parcelas);

  bool get podeConcluir =>
      !salvando && erroData == null && PlanoParcelas.fecha(total, parcelas);

  NovaVendaState copyWith({
    bool? carregando,
    String? Function()? erroCarregar,
    int? passo,
    List<ResumoCliente>? clientes,
    List<ResumoProduto>? produtos,
    List<ResumoServico>? servicos,
    String? Function()? clienteId,
    List<ItemPedido>? itens,
    DateTime? dataVenda,
    bool? aVista,
    List<ParcelaPlano>? parcelas,
    int? versaoPlano,
    bool? entradaRecebida,
    FormaPagamento? formaEntrada,
    String? observacoes,
    String? Function()? erroCliente,
    String? Function()? erroItens,
    String? Function()? erroData,
    bool? salvando,
    String? Function()? idSalvo,
    AvisoToast? Function()? aviso,
    int? versaoPreenchimento,
  }) {
    return NovaVendaState(
      idVenda: idVenda,
      carregando: carregando ?? this.carregando,
      erroCarregar: erroCarregar != null ? erroCarregar() : this.erroCarregar,
      passo: passo ?? this.passo,
      clientes: clientes ?? this.clientes,
      produtos: produtos ?? this.produtos,
      servicos: servicos ?? this.servicos,
      clienteId: clienteId != null ? clienteId() : this.clienteId,
      itens: itens ?? this.itens,
      dataVenda: dataVenda ?? this.dataVenda,
      aVista: aVista ?? this.aVista,
      parcelas: parcelas ?? this.parcelas,
      versaoPlano: versaoPlano ?? this.versaoPlano,
      entradaRecebida: entradaRecebida ?? this.entradaRecebida,
      formaEntrada: formaEntrada ?? this.formaEntrada,
      observacoes: observacoes ?? this.observacoes,
      erroCliente: erroCliente != null ? erroCliente() : this.erroCliente,
      erroItens: erroItens != null ? erroItens() : this.erroItens,
      erroData: erroData != null ? erroData() : this.erroData,
      salvando: salvando ?? this.salvando,
      idSalvo: idSalvo != null ? idSalvo() : this.idSalvo,
      aviso: aviso != null ? aviso() : this.aviso,
      versaoPreenchimento: versaoPreenchimento ?? this.versaoPreenchimento,
    );
  }
}
