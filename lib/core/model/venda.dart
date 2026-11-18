import 'package:sou_consultora/core/model/texto_busca.dart';

/// Situação da venda, calculada das parcelas (nunca gravada).
enum StatusVenda {
  emAberto('Em aberto'),
  atrasada('Atrasada'),
  quitada('Quitada');

  const StatusVenda(this.rotulo);

  final String rotulo;
}

/// Uma venda com a cliente, os itens resumidos e a situação das parcelas
/// (view `resumo_vendas`). Valores em centavos.
class ResumoVenda {
  const ResumoVenda({
    required this.id,
    required this.codigo,
    required this.clienteId,
    required this.clienteNome,
    required this.clienteWhatsapp,
    required this.dataVenda,
    required this.subtotal,
    required this.totalDescontos,
    required this.total,
    this.observacoes,
    this.qtdItens = 0,
    this.qtdUnidades = 0,
    this.nomesItens = '',
    this.primeiroItem,
    this.qtdParcelas = 0,
    this.qtdParcelasPagas = 0,
    this.valorPago = 0,
    this.saldo = 0,
    this.valorAtrasado = 0,
    this.proximoVencimento,
    this.temPagamento = false,
  });

  final String id;
  final int codigo;
  final String clienteId;
  final String clienteNome;
  final String clienteWhatsapp;
  final DateTime dataVenda;
  final int subtotal;
  final int totalDescontos;
  final int total;
  final String? observacoes;
  final int qtdItens;
  final int qtdUnidades;

  /// Nomes dos itens separados por " | " (para a busca).
  final String nomesItens;
  final String? primeiroItem;
  final int qtdParcelas;
  final int qtdParcelasPagas;
  final int valorPago;
  final int saldo;

  /// Saldo das parcelas vencidas antes de hoje.
  final int valorAtrasado;
  final DateTime? proximoVencimento;
  final bool temPagamento;

  /// "#0012".
  String get codigoTexto => '#${codigo.toString().padLeft(4, '0')}';

  /// Quitada → atrasada → em aberto.
  StatusVenda get status {
    if (saldo <= 0) return StatusVenda.quitada;
    if (valorAtrasado > 0) return StatusVenda.atrasada;
    return StatusVenda.emAberto;
  }

  /// Editar só enquanto nenhuma parcela teve pagamento.
  bool get podeEditar => !temPagamento;

  /// "Kit Lily" ou "Kit Lily + 2 itens".
  String get tituloItens {
    final primeiro = primeiroItem ?? 'Venda $codigoTexto';
    if (qtdItens <= 1) return primeiro;
    final outros = qtdItens - 1;
    return '$primeiro + $outros ${outros == 1 ? 'item' : 'itens'}';
  }

  /// "1 item", "3 itens".
  String get textoItens => qtdItens == 1 ? '1 item' : '$qtdItens itens';

  /// Busca por cliente, item ou código ("12", "#12", "#0012"), sem acento.
  bool combinaBusca(String busca) {
    final alvo = busca.trim();
    if (alvo.isEmpty) return true;
    final digitos = alvo.replaceAll('#', '');
    final porCodigo =
        int.tryParse(digitos) != null &&
        codigo.toString() == int.parse(digitos).toString();
    return porCodigo ||
        TextoBusca.contem(clienteNome, alvo) ||
        TextoBusca.contem(nomesItens, alvo);
  }
}
