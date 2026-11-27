import 'package:sou_consultora/core/model/boleto.dart';
import 'package:sou_consultora/core/model/filtro_vendas.dart';
import 'package:sou_consultora/core/model/resumo_financeiro.dart';
import 'package:sou_consultora/core/model/venda.dart';

enum CarregamentoFinanceiro { carregando, pronto, erro }

class FinanceiroState {
  const FinanceiroState({
    required this.hoje,
    required this.periodo,
    this.carregamento = CarregamentoFinanceiro.carregando,
    this.vendas = const [],
    this.boletos = const [],
    this.mensagemErro,
  });

  final DateTime hoje;
  final MesAno periodo;
  final CarregamentoFinanceiro carregamento;
  final List<ResumoVenda> vendas;
  final List<ResumoBoleto> boletos;
  final String? mensagemErro;

  MesAno get mesAtual => MesAno.de(hoje);

  ResumoFinanceiro get resumo => ResumoFinanceiro.calcular(
    vendas: vendas,
    boletos: boletos,
    periodo: periodo,
  );

  List<MesAno> get periodos =>
      ResumoFinanceiro.periodos(vendas: vendas, boletos: boletos, hoje: hoje);

  FinanceiroState copyWith({
    MesAno? periodo,
    CarregamentoFinanceiro? carregamento,
    List<ResumoVenda>? vendas,
    List<ResumoBoleto>? boletos,
    String? Function()? mensagemErro,
  }) {
    return FinanceiroState(
      hoje: hoje,
      periodo: periodo ?? this.periodo,
      carregamento: carregamento ?? this.carregamento,
      vendas: vendas ?? this.vendas,
      boletos: boletos ?? this.boletos,
      mensagemErro: mensagemErro != null ? mensagemErro() : this.mensagemErro,
    );
  }
}
