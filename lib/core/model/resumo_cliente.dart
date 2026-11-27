import 'package:sou_consultora/core/model/cliente.dart';
import 'package:sou_consultora/core/model/texto_busca.dart';

/// Situação exibida no selo da cliente, em ordem de prioridade.
enum SituacaoCliente { atrasada, venceHoje, aniversario, emDia }

/// Cliente com os números financeiros da view `resumo_clientes`.
/// Valores em centavos.
class ResumoCliente {
  const ResumoCliente({
    required this.id,
    required this.nome,
    required this.whatsapp,
    required this.criadaEm,
    this.dataNascimento,
    this.qtdCompras = 0,
    this.totalCompras = 0,
    this.ultimaCompra,
    this.saldoDevedor = 0,
    this.valorAtrasado = 0,
    this.valorVenceHoje = 0,
    this.qtdAtrasadas = 0,
  });

  final String id;
  final String nome;
  final String whatsapp;
  final DateTime criadaEm;
  final DateTime? dataNascimento;
  final int qtdCompras;
  final int totalCompras;
  final DateTime? ultimaCompra;

  /// Tudo o que falta pagar (vencido ou não).
  final int saldoDevedor;
  final int valorAtrasado;
  final int valorVenceHoje;

  /// Quantas parcelas estão vencidas e em aberto.
  final int qtdAtrasadas;

  String get iniciais => Cliente.iniciaisDe(nome);

  bool get comSaldo => saldoDevedor > 0;

  bool aniversarianteNoMes(DateTime hoje) =>
      dataNascimento?.month == hoje.month;

  bool combinaBusca(String busca) => TextoBusca.contem(nome, busca);

  /// Atrasada → vence hoje → aniversário no mês → em dia.
  SituacaoCliente situacao(DateTime hoje) {
    if (valorAtrasado > 0) return SituacaoCliente.atrasada;
    if (valorVenceHoje > 0) return SituacaoCliente.venceHoje;
    if (aniversarianteNoMes(hoje)) return SituacaoCliente.aniversario;
    return SituacaoCliente.emDia;
  }
}
